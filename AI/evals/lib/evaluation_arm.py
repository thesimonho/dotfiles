"""Execute one configuration arm end to end and publish its provenance."""

import os
import uuid
from typing import Any

import mlflow
from mlflow.tracking import MlflowClient

import configuration_components
from agent_environment import build_child_environment
from capabilities import (
    EXTERNAL_EVALUATION_SKILLS,
    REQUIRED_EVALUATION_TOOLS,
    REQUIRED_HOMEOPS_TOOLS,
    CapabilitySnapshot,
    capability_manifest,
    probe_capabilities,
    validate_agent_directory_consistency,
)
from case_execution import (
    build_evaluation_scorer,
    build_predict_fn,
    execution_context,
)
from disposable_workspace import prepare_workspace
from evaluation_case import EvaluationCase
from evaluation_run_identity import (
    CompletedEvaluation,
    EvaluationIdentity,
    WorkspaceSnapshotRecorder,
)
from mlflow_agent_versions import MlflowAgentVersionRegistry
from mlflow_config_registry import MlflowConfigurationRegistry
from mlflow_parameter_names import AGENT_EFFORT_FIELD, AGENT_MODEL_FIELD


def run_evaluation_arm(
    *,
    client: MlflowClient,
    registry: MlflowConfigurationRegistry,
    profile: str,
    components: tuple[configuration_components.ConfigComponent, ...],
    selected_cases: tuple[EvaluationCase, ...],
    evaluation_data: Any,
    experiment_id: str,
    baseline_manifest_version: int | None,
    model: str,
    effort: str,
    profile_environment: dict[str, str] | None = None,
    agent_definition_canary: str | None = None,
    comparison_group_id: str | None = None,
    comparison_variant: str | None = None,
    ablated_component_id: str | None = None,
    advance_baseline_alias: bool = True,
) -> CompletedEvaluation:
    """Execute one configuration against a fixed selected case set."""
    capability_snapshots = _preflight_case_capabilities(
        profile,
        selected_cases,
        model=model,
        effort=effort,
        profile_environment=profile_environment,
        required_agents=component_names(components, "agent"),
        required_skills=(
            *EXTERNAL_EVALUATION_SKILLS,
            *component_names(components, "skill"),
        ),
    )
    publication = registry.prepare(
        components,
        baseline_version=baseline_manifest_version,
    )
    identity = EvaluationIdentity(
        profile=profile,
        model=model,
        effort=effort,
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
            agent_definition_canary=agent_definition_canary,
            workspace_snapshots=workspace_snapshots,
        )
    )
    metrics_by_case_id = {case["case_id"]: case["metrics"] for case in selected_cases}
    results = mlflow.genai.evaluate(
        data=evaluation_data,
        predict_fn=predict_function,
        scorers=[
            build_evaluation_scorer(identity, metrics_by_case_id, profile_environment)
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
        agent_model=identity.model,
        agent_effort=identity.effort,
        expected_trace_count=len(selected_cases),
        advance_baseline_alias=advance_baseline_alias,
        variant_label=comparison_variant if comparison_group_id is None else None,
    )
    client.log_param(results.run_id, AGENT_MODEL_FIELD, identity.model)
    client.log_param(results.run_id, AGENT_EFFORT_FIELD, identity.effort)
    if comparison_group_id is not None:
        _publish_comparison_arm_metadata(
            client,
            results.run_id,
            comparison_group_id=comparison_group_id,
            comparison_variant=comparison_variant,
            ablated_component_id=ablated_component_id,
        )
    elif comparison_variant is not None:
        client.set_tag(results.run_id, "evaluation.variant", comparison_variant)
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


def print_completed_evaluation(
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


def component_names(
    components: tuple[configuration_components.ConfigComponent, ...],
    component_kind: str,
) -> tuple[str, ...]:
    """Return the discovered component names for one monitored kind."""
    prefix = f"{component_kind}/"
    return tuple(
        component.component_id.removeprefix(prefix)
        for component in components
        if component.component_id.startswith(prefix)
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


def _preflight_case_capabilities(
    profile: str,
    cases: tuple[EvaluationCase, ...],
    model: str,
    effort: str,
    profile_environment: dict[str, str] | None = None,
    *,
    required_agents: tuple[str, ...],
    required_skills: tuple[str, ...],
) -> tuple[CapabilitySnapshot, ...]:
    """Fail before MLflow evaluation when shared capabilities are unavailable."""
    probe_identity = EvaluationIdentity(
        profile=profile,
        model=model,
        effort=effort,
        execution_id="environment-preflight",
        manifest_id="environment-preflight",
    )
    probe_context = execution_context(
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
    validate_agent_directory_consistency(profile, base_environment, required_agents)
    snapshots = [
        probe_capabilities(
            profile,
            base_environment,
            required_tools=REQUIRED_EVALUATION_TOOLS,
            required_skills=required_skills,
            required_agents=required_agents,
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
                    required_skills=required_skills,
                    required_agents=required_agents,
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
