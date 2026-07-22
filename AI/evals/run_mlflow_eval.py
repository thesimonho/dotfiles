"""Run the eval suite through MLflow with complete config provenance."""

import argparse
import os
import sys
import uuid
from collections.abc import Callable
from dataclasses import asdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import agent  # noqa: E402
from agent_execution_context import (  # noqa: E402
    AgentExecutionContext,
    EvaluationRole,
)
import configuration_components  # noqa: E402
from capabilities import (  # noqa: E402
    REQUIRED_EVALUATION_AGENTS,
    REQUIRED_EVALUATION_SKILLS,
    REQUIRED_EVALUATION_TOOLS,
    REQUIRED_HOMEOPS_TOOLS,
    CapabilitySnapshot,
    capability_manifest,
    probe_capabilities,
)
from agent_environment import build_child_environment  # noqa: E402
import dataset_sync  # noqa: E402
from disposable_workspace import prepare_workspace  # noqa: E402
import mlflow  # noqa: E402
import mlflow.genai  # noqa: E402
import mlflow_tracing  # noqa: E402
import scoring  # noqa: E402
from cases import CASES  # noqa: E402
from mlflow.entities import Feedback  # noqa: E402
from mlflow.genai import scorer  # noqa: E402
from mlflow.tracking import MlflowClient  # noqa: E402
from mlflow_agent_versions import MlflowAgentVersionRegistry  # noqa: E402
from mlflow_config_registry import MlflowConfigurationRegistry  # noqa: E402
from harness_environment import AGENT_ARGUMENT_CHOICES  # noqa: E402
from mlflow_parameter_names import (  # noqa: E402
    AGENT_CLI_FIELD,
    CASE_CATEGORY_FIELD,
    CASE_ID_FIELD,
)
from evaluation_case import EvaluationCase, WorkspaceSpec  # noqa: E402


def build_predict_fn(
    profile: str,
    execution_id: str,
    manifest_id: str,
) -> Callable[..., dict[str, object]]:
    """Build a predictor whose external traces share immutable run identity."""

    def predict_fn(
        prompt: str,
        case_id: str,
        category: str,
        workspace: WorkspaceSpec | None = None,
    ) -> dict[str, object]:
        """Run one case while keeping its identity queryable on the trace."""
        _update_trace_preview(
            metadata={
                AGENT_CLI_FIELD: profile,
                CASE_ID_FIELD: case_id,
                CASE_CATEGORY_FIELD: category,
                "evaluation.execution_id": execution_id,
                "config.manifest_id": manifest_id,
            },
            request_preview=prompt,
        )
        execution_context = _execution_context(
            profile=profile,
            case_id=case_id,
            category=category,
            role="agent-under-test",
            execution_id=execution_id,
            manifest_id=manifest_id,
        )
        if workspace is None:
            result = agent.run_agent(prompt, execution_context, profile=profile)
            workspace_evidence = None
        else:
            with prepare_workspace(
                workspace["environment"],
                workspace["scenario"],
            ) as prepared_workspace:
                result = agent.run_agent(
                    prompt,
                    execution_context,
                    profile=profile,
                    workspace_path=prepared_workspace.path,
                    workspace_access=workspace["access"],
                    environment_overrides=prepared_workspace.environment,
                    additional_writable_paths=(
                        prepared_workspace.additional_writable_paths
                    ),
                )
                workspace_evidence = asdict(
                    prepared_workspace.capture_evidence(
                        shell_commands=result.shell_commands,
                    )
                )
        _update_trace_preview(response_preview=result.response)
        output = {
            "response": result.response,
            "execution_evidence": {
                "shell_commands": result.shell_commands,
            },
        }
        if workspace_evidence is not None:
            output["workspace_evidence"] = workspace_evidence
        return output

    return predict_fn


def _update_trace_preview(
    *,
    metadata: dict[str, str] | None = None,
    request_preview: str | None = None,
    response_preview: str | None = None,
) -> None:
    """Update list-view text only when MLflow has opened a trace span."""
    if mlflow.get_current_active_span() is None:
        return
    if request_preview is not None:
        mlflow.update_current_trace(
            metadata=metadata,
            request_preview=request_preview,
        )
    if response_preview is not None:
        mlflow.update_current_trace(response_preview=response_preview)


def build_evaluation_scorer(profile: str, execution_id: str, manifest_id: str):
    """Build a scorer whose judge traces share the evaluation execution ID."""

    @scorer
    def evaluation_score(
        inputs: dict,
        outputs: dict,
        expectations: dict,
    ) -> list[Feedback]:
        """Return every response-derived metric applicable to this case."""
        judge_context = _execution_context(
            profile=profile,
            case_id=inputs["case_id"],
            category=inputs["category"],
            role="judge",
            execution_id=execution_id,
            manifest_id=manifest_id,
        )
        metrics = tuple(
            scoring.metric_from_mapping(metric) for metric in expectations["metrics"]
        )
        response_results = scoring.score_response_metrics(
            outputs["response"],
            metrics,
            judge_context,
            profile=profile,
        )
        execution_results = scoring.score_execution_metrics(
            tuple(outputs["execution_evidence"]["shell_commands"]),
            metrics,
        )
        workspace_results = (
            scoring.score_workspace_metrics(outputs["workspace_evidence"], metrics)
            if "workspace_evidence" in outputs
            else []
        )
        return [
            Feedback(
                name=result.name,
                value=result.value,
                rationale=result.rationale,
            )
            for result in (*response_results, *execution_results, *workspace_results)
        ]

    return evaluation_score


def _execution_context(
    *,
    profile: str,
    case_id: str,
    category: str,
    role: EvaluationRole,
    execution_id: str,
    manifest_id: str,
) -> AgentExecutionContext:
    """Construct the shared immutable identity for an agent CLI process."""
    return AgentExecutionContext(
        agent_cli=profile,
        case_id=case_id,
        category=category,
        evaluation_role=role,
        evaluation_execution_id=execution_id,
        config_manifest_id=manifest_id,
    )


def parse_arguments() -> argparse.Namespace:
    """Parse an optional manifest version to use as the comparison baseline."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--agent",
        choices=AGENT_ARGUMENT_CHOICES,
        default="auto",
        help="Agent CLI and configuration profile to evaluate.",
    )
    parser.add_argument(
        "--baseline-manifest-version",
        type=int,
        help="Compare against this MLflow manifest prompt version instead of the latest.",
    )
    parser.add_argument(
        "--case-id",
        action="append",
        dest="case_ids",
        help="Evaluate only this case ID without replacing the complete hosted dataset.",
    )
    return parser.parse_args()


def run_evaluation(arguments: argparse.Namespace) -> None:
    """Run one evaluation after rejecting an unconfigured case suite."""
    if not CASES:
        raise RuntimeError(
            "no evaluation cases configured; add real cases to AI/evals/cases.py"
        )

    selected_cases = _selected_cases(arguments.case_ids)
    agent_profile = agent.resolve_agent_profile(arguments.agent)
    capability_snapshots = _preflight_case_capabilities(
        agent_profile,
        selected_cases,
    )
    mlflow_tracing.init()
    client = MlflowClient()
    registry = MlflowConfigurationRegistry(
        client,
        mlflow.genai,
        profile=agent_profile,
    )
    components = configuration_components.discover_agent_components(agent_profile)
    publication = registry.prepare(
        components,
        baseline_version=arguments.baseline_manifest_version,
    )
    execution_id = str(uuid.uuid4())

    experiment = mlflow.get_experiment_by_name(mlflow_tracing.EXPERIMENT_NAME)
    if experiment is None:
        raise RuntimeError(
            f"MLflow experiment was not created: {mlflow_tracing.EXPERIMENT_NAME}"
        )
    experiment_id = experiment.experiment_id
    agent_version_registry = MlflowAgentVersionRegistry(client, mlflow)
    agent_version = agent_version_registry.resolve(
        publication,
        experiment_id,
    )
    dataset = dataset_sync.sync_mlflow_dataset(CASES, experiment_id)
    evaluation_data = (
        dataset_sync.mlflow_records(selected_cases) if arguments.case_ids else dataset
    )

    os.environ.setdefault("MLFLOW_GENAI_EVAL_SKIP_TRACE_VALIDATION", "true")
    predict_function = mlflow.trace(
        build_predict_fn(
            agent_profile,
            execution_id,
            publication.manifest.manifest_id,
        )
    )
    results = mlflow.genai.evaluate(
        data=evaluation_data,
        predict_fn=predict_function,
        scorers=[
            build_evaluation_scorer(
                agent_profile,
                execution_id,
                publication.manifest.manifest_id,
            )
        ],
        model_id=agent_version.model_id,
    )
    agent_version_registry.publish_configuration_evidence(
        publication,
        agent_version,
    )
    _publish_capability_evidence(client, results.run_id, capability_snapshots)
    registry.attach_to_run(
        results.run_id,
        publication,
        expected_trace_count=len(selected_cases),
        external_trace_execution_id=execution_id,
        expected_external_invocation_count=_external_invocation_count(selected_cases),
    )

    print(results)
    print(
        f"configuration manifest: {publication.run_metadata['config_manifest_prompt']}"
    )
    print(f"agent version: {agent_version.model_id}")
    print(f"evaluation execution: {execution_id}")
    print(publication.changes.summary)


def _selected_cases(case_ids: list[str] | None) -> tuple[EvaluationCase, ...]:
    """Resolve focused case IDs while retaining the complete hosted dataset."""
    if not case_ids:
        return CASES
    requested_case_ids = set(case_ids)
    selected_cases = tuple(
        case for case in CASES if case["case_id"] in requested_case_ids
    )
    missing_case_ids = requested_case_ids - {case["case_id"] for case in selected_cases}
    if missing_case_ids:
        raise ValueError(f"unknown evaluation case IDs: {', '.join(missing_case_ids)}")
    return selected_cases


def _preflight_case_capabilities(
    profile: str,
    cases: tuple[EvaluationCase, ...],
) -> tuple[CapabilitySnapshot, ...]:
    """Fail before MLflow evaluation when shared capabilities are unavailable."""
    probe_context = _execution_context(
        profile=profile,
        case_id="environment-preflight",
        category="environment-preflight",
        role="agent-under-test",
        execution_id="environment-preflight",
        manifest_id="environment-preflight",
    )
    base_environment = build_child_environment(os.environ, probe_context)
    snapshots = [
        probe_capabilities(
            profile,
            base_environment,
            required_tools=REQUIRED_EVALUATION_TOOLS,
            required_skills=REQUIRED_EVALUATION_SKILLS,
            required_agents=REQUIRED_EVALUATION_AGENTS,
        )
    ]
    checked_environments = set()
    for case in cases:
        workspace = case.get("workspace")
        if workspace is None:
            continue
        environment_identity = (workspace["environment"], workspace["scenario"])
        if environment_identity in checked_environments:
            continue
        checked_environments.add(environment_identity)
        with prepare_workspace(*environment_identity) as prepared_workspace:
            child_environment = build_child_environment(
                os.environ,
                probe_context,
                overrides=prepared_workspace.environment,
            )
            snapshots.append(
                probe_capabilities(
                    profile,
                    child_environment,
                    required_tools=(
                        *REQUIRED_EVALUATION_TOOLS,
                        *REQUIRED_HOMEOPS_TOOLS,
                    ),
                    required_skills=REQUIRED_EVALUATION_SKILLS,
                    required_agents=REQUIRED_EVALUATION_AGENTS,
                )
            )
    return tuple(snapshots)


def _publish_capability_evidence(
    client: MlflowClient,
    run_id: str,
    snapshots: tuple[CapabilitySnapshot, ...],
) -> None:
    """Attach path-redacted capability hashes to the inspectable MLflow run."""
    manifest = capability_manifest(snapshots)
    client.log_dict(run_id, manifest, "capabilities/manifest.json")
    client.set_tag(run_id, "evaluation.capabilities_hash", manifest["manifest_hash"])


def _external_invocation_count(cases: tuple[EvaluationCase, ...]) -> int:
    """Count agent-under-test and LLM-judge CLI processes expected this run."""
    judge_count = sum(
        any(metric["evaluator"] == "output-quality" for metric in case["metrics"])
        for case in cases
    )
    return len(cases) + judge_count


if __name__ == "__main__":
    run_evaluation(parse_arguments())
