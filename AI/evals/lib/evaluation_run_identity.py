"""Immutable identity and result records shared by evaluation arms."""

from dataclasses import dataclass, field

from tracking.parameter_names import AGENT_EFFORT_FIELD, AGENT_MODEL_FIELD


@dataclass(frozen=True)
class EvaluationIdentity:
    """Immutable run and comparison identity shared by traces and CLIs."""

    profile: str
    model: str
    effort: str
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
            AGENT_MODEL_FIELD: self.model,
            AGENT_EFFORT_FIELD: self.effort,
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
