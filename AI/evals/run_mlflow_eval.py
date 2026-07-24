"""Run the eval suite through MLflow with complete config provenance."""

import argparse
import os
import sys
import time
import uuid
from collections.abc import Callable
from contextlib import ExitStack
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Literal, cast

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import agent  # noqa: E402
from agent_execution_context import (  # noqa: E402
    AgentExecutionContext,
    EvaluationRole,
)
from agent_event_contract import (  # noqa: E402
    EvidenceRequirement,
    validate_case_evidence_requirements,
)
import configuration_components  # noqa: E402
from comparison_evidence import (  # noqa: E402
    ComparisonArmResult,
    build_comparison_evidence,
)
from configuration_variant import (  # noqa: E402
    comparison_variants,
    prepare_variant_profile,
)
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
from mlflow_execution_trace import invoke_traced_agent  # noqa: E402
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
from evaluation_operational_feedback import operational_feedback  # noqa: E402


@dataclass(frozen=True)
class EvaluationIdentity:
    """Immutable run and comparison identity shared by traces and CLIs."""

    profile: str
    execution_id: str
    manifest_id: str
    comparison_group_id: str | None = None
    comparison_variant: str | None = None
    ablated_component_id: str | None = None

    def trace_metadata(self) -> dict[str, str]:
        """Return optional comparison fields for native MLflow traces."""
        metadata = {
            "evaluation.execution_id": self.execution_id,
            "config.manifest_id": self.manifest_id,
        }
        optional_metadata = {
            "evaluation.comparison_group_id": self.comparison_group_id,
            "evaluation.variant": self.comparison_variant,
            "evaluation.ablated_component_id": self.ablated_component_id,
        }
        metadata.update(
            {
                name: value
                for name, value in optional_metadata.items()
                if value is not None
            }
        )
        return metadata


@dataclass
class WorkspaceSnapshotRecorder:
    """Collect initial workspace identities observed during one arm."""

    hashes: dict[str, str] = field(default_factory=dict)

    def record(self, case_id: str, snapshot_hash: str) -> None:
        """Reject inconsistent retries of the same case inside one arm."""
        previous_hash = self.hashes.get(case_id)
        if previous_hash is not None and previous_hash != snapshot_hash:
            raise RuntimeError(f"case {case_id} used multiple workspace snapshots")
        self.hashes[case_id] = snapshot_hash


@dataclass(frozen=True)
class CompletedEvaluation:
    """Inspectable result from one complete MLflow evaluation arm."""

    run_id: str
    execution_id: str
    manifest_id: str
    manifest_prompt: str
    model_id: str
    metrics: dict[str, float]
    workspace_snapshot_hashes: dict[str, str]
    change_summary: str


def build_predict_fn(
    identity: EvaluationIdentity,
    profile_environment: dict[str, str] | None = None,
    workspace_snapshots: WorkspaceSnapshotRecorder | None = None,
) -> Callable[..., dict[str, object]]:
    """Build a predictor whose external traces share immutable run identity."""

    def predict_fn(
        prompt: str,
        case_id: str,
        category: str,
        required_evidence: list[str] | tuple[str, ...],
        required_observed_evidence: list[str] | tuple[str, ...],
        workspace: WorkspaceSpec | None = None,
    ) -> dict[str, object]:
        """Run one case while keeping its identity queryable on the trace."""
        case_started_at = time.perf_counter()
        _update_trace_preview(
            metadata={
                AGENT_CLI_FIELD: identity.profile,
                CASE_ID_FIELD: case_id,
                CASE_CATEGORY_FIELD: category,
                **identity.trace_metadata(),
            },
            request_preview=prompt,
        )
        execution_context = _execution_context(
            identity=identity,
            case_id=case_id,
            category=category,
            role="agent-under-test",
        )
        if not all(isinstance(requirement, str) for requirement in required_evidence):
            raise TypeError("case evidence requirements must be strings")
        evidence_requirements: tuple[EvidenceRequirement, ...] = tuple(
            cast(EvidenceRequirement, requirement) for requirement in required_evidence
        )
        if not all(
            isinstance(requirement, str) for requirement in required_observed_evidence
        ):
            raise TypeError("observed evidence requirements must be strings")
        observed_evidence_requirements: tuple[EvidenceRequirement, ...] = tuple(
            cast(EvidenceRequirement, requirement)
            for requirement in required_observed_evidence
        )
        if workspace is None:
            result = invoke_traced_agent(
                lambda: agent.run_agent(
                    prompt,
                    execution_context,
                    profile=identity.profile,
                    environment_overrides=profile_environment,
                ),
                evidence_requirements,
                observed_evidence_requirements,
            )
            workspace_evidence = None
        else:
            workspace_stack = ExitStack()
            try:
                with mlflow.start_span(
                    name="workspace.prepare",
                    span_type="CHAIN",
                ):
                    prepared_workspace = workspace_stack.enter_context(
                        prepare_workspace(
                            workspace["environment"],
                            workspace["scenario"],
                        )
                    )
                if workspace_snapshots is not None:
                    workspace_snapshots.record(
                        case_id,
                        prepared_workspace.workspace_snapshot_hash,
                    )
                result = invoke_traced_agent(
                    lambda: agent.run_agent(
                        prompt,
                        execution_context,
                        profile=identity.profile,
                        workspace_path=prepared_workspace.path,
                        workspace_access=workspace["access"],
                        environment_overrides={
                            **(profile_environment or {}),
                            **prepared_workspace.environment,
                        },
                        additional_writable_paths=(
                            prepared_workspace.additional_writable_paths
                        ),
                    ),
                    evidence_requirements,
                    observed_evidence_requirements,
                )
                with mlflow.start_span(
                    name="workspace.capture",
                    span_type="CHAIN",
                ) as capture_span:
                    workspace_evidence = asdict(
                        prepared_workspace.capture_evidence(
                            shell_commands=result.shell_commands,
                        )
                    )
                    capture_span.set_outputs(workspace_evidence)
            finally:
                with mlflow.start_span(
                    name="workspace.cleanup",
                    span_type="CHAIN",
                ):
                    workspace_stack.close()
        _update_trace_preview(response_preview=result.response)
        case_completion_seconds = time.perf_counter() - case_started_at
        output = {
            "response": result.response,
            "execution_evidence": {
                "shell_commands": result.shell_commands,
                "events": tuple(event.to_dict() for event in result.events),
                "model_ids": result.model_ids,
                "required_evidence": evidence_requirements,
                "required_observed_evidence": observed_evidence_requirements,
                "event_coverage": result.event_coverage.to_dict(),
            },
            "operational_evidence": {
                "case_completion_seconds": case_completion_seconds,
                "agent_invocation_seconds": result.invocation_seconds,
                "token_usage": result.token_usage.to_dict(),
            },
        }
        active_span = mlflow.get_current_active_span()
        if active_span is not None:
            active_span.set_attributes(
                {
                    "evaluation.case_completion_seconds": case_completion_seconds,
                    "evaluation.agent_invocation_seconds": result.invocation_seconds,
                }
            )
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


def build_evaluation_scorer(identity: EvaluationIdentity):
    """Build a scorer whose judge traces share the evaluation execution ID."""

    @scorer
    def evaluation_score(
        inputs: dict,
        outputs: dict,
        expectations: dict,
    ) -> list[Feedback]:
        """Return every response-derived metric applicable to this case."""
        judge_context = _execution_context(
            identity=identity,
            case_id=inputs["case_id"],
            category=inputs["category"],
            role="judge",
        )
        metrics = tuple(
            scoring.metric_from_mapping(metric) for metric in expectations["metrics"]
        )
        response_results = scoring.score_response_metrics(
            outputs["response"],
            metrics,
            judge_context,
            profile=identity.profile,
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
        behavioral_feedback = [
            Feedback(
                name=result.name,
                value=result.value,
                rationale=result.rationale,
            )
            for result in (*response_results, *execution_results, *workspace_results)
        ]
        return [
            *behavioral_feedback,
            *operational_feedback(
                outputs["operational_evidence"],
                outputs["execution_evidence"],
            ),
        ]

    return evaluation_score


def _execution_context(
    *,
    identity: EvaluationIdentity,
    case_id: str,
    category: str,
    role: EvaluationRole,
) -> AgentExecutionContext:
    """Construct the shared immutable identity for an agent CLI process."""
    return AgentExecutionContext(
        agent_cli=identity.profile,
        case_id=case_id,
        category=category,
        evaluation_role=role,
        evaluation_execution_id=identity.execution_id,
        config_manifest_id=identity.manifest_id,
        comparison_group_id=identity.comparison_group_id,
        comparison_variant=identity.comparison_variant,
        ablated_component_id=identity.ablated_component_id,
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
    parser.add_argument(
        "--compare-component",
        help=(
            "Run treatment and control arms, removing exactly this instruction "
            "component from the control configuration."
        ),
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
    validate_case_evidence_requirements(agent_profile, selected_cases)
    mlflow_tracing.init()
    client = MlflowClient()
    registry = MlflowConfigurationRegistry(
        client,
        mlflow.genai,
        profile=agent_profile,
    )
    components = configuration_components.discover_agent_components(agent_profile)
    experiment = mlflow.get_experiment_by_name(mlflow_tracing.EXPERIMENT_NAME)
    if experiment is None:
        raise RuntimeError(
            f"MLflow experiment was not created: {mlflow_tracing.EXPERIMENT_NAME}"
        )
    experiment_id = experiment.experiment_id
    dataset = dataset_sync.sync_mlflow_dataset(CASES, experiment_id)
    evaluation_data = (
        dataset_sync.mlflow_records(selected_cases) if arguments.case_ids else dataset
    )

    if arguments.compare_component:
        _run_component_comparison(
            client=client,
            registry=registry,
            profile=agent_profile,
            components=components,
            component_id=arguments.compare_component,
            selected_cases=selected_cases,
            evaluation_data=evaluation_data,
            experiment_id=experiment_id,
            baseline_manifest_version=arguments.baseline_manifest_version,
        )
        return

    completed = _run_evaluation_arm(
        client=client,
        registry=registry,
        profile=agent_profile,
        components=components,
        selected_cases=selected_cases,
        evaluation_data=evaluation_data,
        experiment_id=experiment_id,
        baseline_manifest_version=arguments.baseline_manifest_version,
    )
    _print_completed_evaluation(completed)


def _run_component_comparison(
    *,
    client: MlflowClient,
    registry: MlflowConfigurationRegistry,
    profile: str,
    components: tuple[configuration_components.ConfigComponent, ...],
    component_id: str,
    selected_cases: tuple[EvaluationCase, ...],
    evaluation_data: Any,
    experiment_id: str,
    baseline_manifest_version: int | None,
) -> None:
    """Run full and single-component-ablated arms and publish paired deltas."""
    comparison_group_id = str(uuid.uuid4())
    treatment_variant, control_variant = comparison_variants(
        components,
        component_id,
    )
    completed_by_variant: dict[str, CompletedEvaluation] = {}
    for variant in (treatment_variant, control_variant):
        with prepare_variant_profile(profile, variant) as prepared_profile:
            completed_by_variant[variant.name] = _run_evaluation_arm(
                client=client,
                registry=registry,
                profile=profile,
                components=variant.components,
                selected_cases=selected_cases,
                evaluation_data=evaluation_data,
                experiment_id=experiment_id,
                baseline_manifest_version=baseline_manifest_version,
                profile_environment=prepared_profile.environment,
                comparison_group_id=comparison_group_id,
                comparison_variant=variant.name,
                ablated_component_id=component_id,
                advance_baseline_alias=variant.name == "treatment",
            )
    treatment = _comparison_arm_result(
        "treatment",
        completed_by_variant["treatment"],
    )
    control = _comparison_arm_result(
        "control",
        completed_by_variant["control"],
    )
    evidence = build_comparison_evidence(
        comparison_group_id=comparison_group_id,
        ablated_component_id=component_id,
        treatment=treatment,
        control=control,
    )
    _publish_comparison_evidence(client, evidence, treatment, control)
    _print_completed_evaluation(completed_by_variant["treatment"], "treatment")
    _print_completed_evaluation(completed_by_variant["control"], "control")
    print(f"comparison group: {comparison_group_id}")
    print(f"ablated component: {component_id}")
    for metric_name, delta in evidence["metric_deltas"].items():
        print(
            f"{metric_name}: treatment={delta['treatment']} "
            f"control={delta['control']} improvement={delta['improvement']}"
        )


def _run_evaluation_arm(
    *,
    client: MlflowClient,
    registry: MlflowConfigurationRegistry,
    profile: str,
    components: tuple[configuration_components.ConfigComponent, ...],
    selected_cases: tuple[EvaluationCase, ...],
    evaluation_data: Any,
    experiment_id: str,
    baseline_manifest_version: int | None,
    profile_environment: dict[str, str] | None = None,
    comparison_group_id: str | None = None,
    comparison_variant: str | None = None,
    ablated_component_id: str | None = None,
    advance_baseline_alias: bool = True,
) -> CompletedEvaluation:
    """Execute one configuration against a fixed selected case set."""
    capability_snapshots = _preflight_case_capabilities(
        profile,
        selected_cases,
        profile_environment=profile_environment,
    )
    publication = registry.prepare(
        components,
        baseline_version=baseline_manifest_version,
    )
    identity = EvaluationIdentity(
        profile=profile,
        execution_id=str(uuid.uuid4()),
        manifest_id=publication.manifest.manifest_id,
        comparison_group_id=comparison_group_id,
        comparison_variant=comparison_variant,
        ablated_component_id=ablated_component_id,
    )
    agent_version_registry = MlflowAgentVersionRegistry(client, mlflow)
    agent_version = agent_version_registry.resolve(publication, experiment_id)
    workspace_snapshots = WorkspaceSnapshotRecorder()

    os.environ.setdefault("MLFLOW_GENAI_EVAL_SKIP_TRACE_VALIDATION", "true")
    predict_function = mlflow.trace(
        build_predict_fn(
            identity,
            profile_environment=profile_environment,
            workspace_snapshots=workspace_snapshots,
        )
    )
    results = mlflow.genai.evaluate(
        data=evaluation_data,
        predict_fn=predict_function,
        scorers=[build_evaluation_scorer(identity)],
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
        external_trace_execution_id=identity.execution_id,
        expected_external_invocation_count=_external_invocation_count(selected_cases),
        advance_baseline_alias=advance_baseline_alias,
    )
    if comparison_group_id is not None:
        _publish_comparison_arm_metadata(
            client,
            results.run_id,
            comparison_group_id=comparison_group_id,
            comparison_variant=comparison_variant,
            ablated_component_id=ablated_component_id,
        )
    return CompletedEvaluation(
        run_id=results.run_id,
        execution_id=identity.execution_id,
        manifest_id=publication.manifest.manifest_id,
        manifest_prompt=publication.run_metadata["config_manifest_prompt"],
        model_id=agent_version.model_id,
        metrics={name: float(value) for name, value in results.metrics.items()},
        workspace_snapshot_hashes=dict(workspace_snapshots.hashes),
        change_summary=publication.changes.summary,
    )


def _comparison_arm_result(
    variant: Literal["treatment", "control"],
    completed: CompletedEvaluation,
) -> ComparisonArmResult:
    """Narrow a completed run to the durable paired-comparison contract."""
    return ComparisonArmResult(
        variant=variant,
        run_id=completed.run_id,
        manifest_id=completed.manifest_id,
        metrics=completed.metrics,
        workspace_snapshot_hashes=completed.workspace_snapshot_hashes,
    )


def _publish_comparison_arm_metadata(
    client: MlflowClient,
    run_id: str,
    *,
    comparison_group_id: str,
    comparison_variant: str | None,
    ablated_component_id: str | None,
) -> None:
    """Make experimental arm identity filterable from MLflow runs."""
    if comparison_variant is None or ablated_component_id is None:
        raise ValueError("comparison metadata requires variant and component")
    client.set_tag(run_id, "evaluation.comparison_group_id", comparison_group_id)
    client.set_tag(run_id, "evaluation.variant", comparison_variant)
    client.set_tag(run_id, "evaluation.ablated_component_id", ablated_component_id)


def _publish_comparison_evidence(
    client: MlflowClient,
    evidence: dict[str, Any],
    treatment: ComparisonArmResult,
    control: ComparisonArmResult,
) -> None:
    """Attach the same paired artifact and counterpart identity to both runs."""
    for arm, counterpart in ((treatment, control), (control, treatment)):
        client.log_dict(arm.run_id, evidence, "comparison/result.json")
        client.set_tag(arm.run_id, "evaluation.counterpart_run_id", counterpart.run_id)


def _print_completed_evaluation(
    completed: CompletedEvaluation,
    label: str | None = None,
) -> None:
    """Print stable identities needed to reopen one completed run."""
    prefix = f"{label} " if label else ""
    print(f"{prefix}run: {completed.run_id}")
    print(f"{prefix}configuration manifest: {completed.manifest_prompt}")
    print(f"{prefix}agent version: {completed.model_id}")
    print(f"{prefix}evaluation execution: {completed.execution_id}")
    print(completed.change_summary)


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
    profile_environment: dict[str, str] | None = None,
) -> tuple[CapabilitySnapshot, ...]:
    """Fail before MLflow evaluation when shared capabilities are unavailable."""
    probe_identity = EvaluationIdentity(
        profile=profile,
        execution_id="environment-preflight",
        manifest_id="environment-preflight",
    )
    probe_context = _execution_context(
        identity=probe_identity,
        case_id="environment-preflight",
        category="environment-preflight",
        role="agent-under-test",
    )
    base_environment = build_child_environment(
        os.environ,
        probe_context,
        overrides=profile_environment,
    )
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
                overrides={
                    **(profile_environment or {}),
                    **prepared_workspace.environment,
                },
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
