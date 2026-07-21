"""Run the eval suite through MLflow with complete config provenance."""

import argparse
import sys
import uuid
from collections.abc import Callable
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import agent  # noqa: E402
from agent_execution_context import (  # noqa: E402
    AgentExecutionContext,
    EvaluationRole,
)
import configuration_components  # noqa: E402
import dataset_sync  # noqa: E402
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


def build_predict_fn(
    profile: str,
    execution_id: str,
    manifest_id: str,
) -> Callable[[str, str, str], dict[str, object]]:
    """Build a predictor whose external traces share immutable run identity."""

    def predict_fn(prompt: str, case_id: str, category: str) -> dict[str, object]:
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
        result = agent.run_agent(
            prompt,
            _execution_context(
                profile=profile,
                case_id=case_id,
                category=category,
                role="agent-under-test",
                execution_id=execution_id,
                manifest_id=manifest_id,
            ),
            profile=profile,
        )
        _update_trace_preview(response_preview=result.response)
        return {
            "response": result.response,
            "execution_evidence": {
                "shell_commands": result.shell_commands,
            },
        }

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
        return [
            Feedback(
                name=result.name,
                value=result.value,
                rationale=result.rationale,
            )
            for result in (*response_results, *execution_results)
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
    return parser.parse_args()


def run_evaluation(arguments: argparse.Namespace) -> None:
    """Run one evaluation after rejecting an unconfigured case suite."""
    if not CASES:
        raise RuntimeError(
            "no evaluation cases configured; add real cases to AI/evals/cases.py"
        )

    agent_profile = agent.resolve_agent_profile(arguments.agent)
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

    results = mlflow.genai.evaluate(
        data=dataset,
        predict_fn=build_predict_fn(
            agent_profile,
            execution_id,
            publication.manifest.manifest_id,
        ),
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
    registry.attach_to_run(
        results.run_id,
        publication,
        expected_trace_count=len(CASES),
        external_trace_execution_id=execution_id,
        expected_external_invocation_count=_external_invocation_count(),
    )

    print(results)
    print(
        f"configuration manifest: {publication.run_metadata['config_manifest_prompt']}"
    )
    print(f"agent version: {agent_version.model_id}")
    print(f"evaluation execution: {execution_id}")
    print(publication.changes.summary)


def _external_invocation_count() -> int:
    """Count agent-under-test and LLM-judge CLI processes expected this run."""
    judge_count = sum(
        any(metric["evaluator"] == "output-quality" for metric in case["metrics"])
        for case in CASES
    )
    return len(CASES) + judge_count


if __name__ == "__main__":
    run_evaluation(parse_arguments())
