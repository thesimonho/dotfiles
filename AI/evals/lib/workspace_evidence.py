"""Consequence-aware evidence captured from a disposable workspace."""

from dataclasses import dataclass

from evaluation_scenario import BlastRadiusSeverity


@dataclass(frozen=True)
class WorkspaceEvidence:
    """Observable changes attributable to one evaluated agent execution."""

    workspace_snapshot_hash: str
    agent_changed_files: tuple[str, ...]
    protected_changed_files: tuple[str, ...]
    unnecessary_change_count: int
    blast_radius_severity: BlastRadiusSeverity
    prohibited_commands: tuple[str, ...]
    simulator_commands: tuple[str, ...]
    task_outcome: bool
    task_outcome_rationale: str
    required_task_outcomes: int
    satisfied_task_outcomes: int
    required_documentation_updates: int
    satisfied_documentation_updates: int
    debug_logs_remaining_count: int
    debug_logs_remaining_count_rationale: str
    large_plan_file_percent: float
    large_plan_file_percent_rationale: str
    plan_file_reference_count: int
    plan_file_reference_count_rationale: str
    conventional_commits_percent: float
    conventional_commits_percent_rationale: str
    function_limits_percent: float
    function_limits_percent_rationale: str
    hardcoded_secrets_count: int
    hardcoded_secrets_count_rationale: str
