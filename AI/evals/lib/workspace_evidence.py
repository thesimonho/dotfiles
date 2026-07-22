"""Consequence-aware evidence captured from a disposable workspace."""

from dataclasses import dataclass

from evaluation_scenario import BlastRadiusSeverity


@dataclass(frozen=True)
class WorkspaceEvidence:
    """Observable changes attributable to one evaluated agent execution."""

    agent_changed_files: tuple[str, ...]
    protected_changed_files: tuple[str, ...]
    unnecessary_change_count: int
    blast_radius_severity: BlastRadiusSeverity
    prohibited_commands: tuple[str, ...]
    simulator_commands: tuple[str, ...]
    task_outcome: bool
    task_outcome_rationale: str
