"""Paired treatment/control comparison orchestration for one component."""

import uuid
from typing import Any, Literal

from mlflow.tracking import MlflowClient

import configuration.components as configuration_components
from evidence.comparison import ComparisonArmResult, build_comparison_evidence
from configuration.variant import (
    comparison_variants,
    new_agent_definition_canary,
    prepare_variant_profile,
)
from evaluation_arm import print_completed_evaluation, run_evaluation_arm
from evaluation_case import EvaluationCase
from evaluation_run_identity import CompletedEvaluation
from tracking.config_registry import MlflowConfigurationRegistry


def run_component_comparison(
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
    model: str,
    effort: str,
    advance_baseline: bool = True,
) -> None:
    """Run full and single-component-ablated arms and publish paired deltas."""
    comparison_group_id = str(uuid.uuid4())
    treatment_variant, control_variant = comparison_variants(
        components,
        component_id,
    )
    completed_by_variant: dict[str, CompletedEvaluation] = {}
    agent_definition_canary = new_agent_definition_canary()
    for variant in (treatment_variant, control_variant):
        with prepare_variant_profile(
            profile,
            variant,
            agent_definition_canary=agent_definition_canary,
        ) as prepared_profile:
            completed_by_variant[variant.name] = run_evaluation_arm(
                client=client,
                registry=registry,
                profile=profile,
                components=variant.components,
                selected_cases=selected_cases,
                evaluation_data=evaluation_data,
                experiment_id=experiment_id,
                baseline_manifest_version=baseline_manifest_version,
                model=model,
                effort=effort,
                profile_environment=prepared_profile.environment,
                agent_definition_canary=prepared_profile.agent_definition_canary,
                comparison_group_id=comparison_group_id,
                comparison_variant=variant.name,
                ablated_component_id=component_id,
                advance_baseline_alias=advance_baseline
                and variant.name == "treatment",
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
    print_completed_evaluation(completed_by_variant["treatment"], "treatment")
    print_completed_evaluation(completed_by_variant["control"], "control")
    print(f"comparison group: {comparison_group_id}")
    print(f"ablated component: {component_id}")
    for metric_name, delta in evidence["metric_deltas"].items():
        print(
            f"{metric_name}: treatment={delta['treatment']} "
            f"control={delta['control']} improvement={delta['improvement']}"
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
