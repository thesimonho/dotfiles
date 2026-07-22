"""Inspectable evidence for paired instruction-fragment comparisons."""

from dataclasses import asdict, dataclass
from typing import Any, Literal

type ComparisonVariantName = Literal["treatment", "control"]
type MetricDirection = Literal["higher-is-better", "lower-is-better", "diagnostic"]

HIGHER_IS_BETTER_METRICS = {
    "all_shell_commands_prefixed",
    "answer_correct",
    "negative_constraints_followed",
    "protected_resources_preserved",
    "shell_command_prefix_rate",
    "task_outcome",
    "used_structured_parser",
}
LOWER_IS_BETTER_METRICS = {
    "blast_radius_severity",
    "unnecessary_change_count",
}


@dataclass(frozen=True)
class ComparisonArmResult:
    """Run identity and outcomes needed to compare one experimental arm."""

    variant: ComparisonVariantName
    run_id: str
    manifest_id: str
    metrics: dict[str, float]
    workspace_snapshot_hashes: dict[str, str]


def build_comparison_evidence(
    *,
    comparison_group_id: str,
    ablated_component_id: str,
    treatment: ComparisonArmResult,
    control: ComparisonArmResult,
) -> dict[str, Any]:
    """Build paired deltas after proving both arms used identical workspaces."""
    if treatment.workspace_snapshot_hashes != control.workspace_snapshot_hashes:
        raise ValueError("comparison arms used different workspace snapshots")
    shared_metric_names = sorted(treatment.metrics.keys() & control.metrics.keys())
    metric_deltas = {
        metric_name: _metric_delta(
            metric_name,
            treatment.metrics[metric_name],
            control.metrics[metric_name],
        )
        for metric_name in shared_metric_names
    }
    return {
        "comparison_group_id": comparison_group_id,
        "ablated_component_id": ablated_component_id,
        "workspace_snapshot_hashes": treatment.workspace_snapshot_hashes,
        "arms": {
            "treatment": asdict(treatment),
            "control": asdict(control),
        },
        "metric_deltas": metric_deltas,
    }


def _metric_delta(
    metric_name: str,
    treatment_value: float,
    control_value: float,
) -> dict[str, float | str | None]:
    """Report raw change and improvement without inventing an aggregate score."""
    direction = _metric_direction(metric_name)
    raw_delta = treatment_value - control_value
    if direction == "higher-is-better":
        improvement = raw_delta
    elif direction == "lower-is-better":
        improvement = -raw_delta
    else:
        improvement = None
    return {
        "control": control_value,
        "treatment": treatment_value,
        "treatment_minus_control": raw_delta,
        "improvement": improvement,
        "direction": direction,
    }


def _metric_direction(metric_name: str) -> MetricDirection:
    """Return explicit interpretation for a reusable metric name."""
    base_name = metric_name.removesuffix("/mean")
    if base_name in HIGHER_IS_BETTER_METRICS:
        return "higher-is-better"
    if base_name in LOWER_IS_BETTER_METRICS:
        return "lower-is-better"
    return "diagnostic"
