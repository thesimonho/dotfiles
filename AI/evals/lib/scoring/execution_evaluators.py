"""Evaluators whose evidence is normalized shell commands and agent events."""

import os
from dataclasses import dataclass
from typing import Any

from evaluation_case import (
    AllShellCommandsPrefixedMetric,
    CommonMetric,
    EvidenceCountMetric,
    EvidenceRequirementsPercentMetric,
    PolicyMetric,
    ShellCommandPrefixRateMetric,
    UsedCommandMetric,
)
from scoring.event_sequences import (
    score_branch_before_changes,
    score_final_verify,
    score_tdd_sequence,
    score_worktree_lifecycle,
)
from shell_commands import executable_index, shell_segments

type MetricValue = bool | int | float | str
type ScoredMetric = tuple[MetricValue, str] | None


@dataclass(frozen=True)
class ExecutionEvidence:
    """Everything an execution-derived evaluator may consult."""

    shell_commands: tuple[str, ...]
    events: tuple[dict[str, Any], ...]
    agent_profile: str | None
    parent_model: str | None
    parent_effort: str | None


def _evaluate_used_command(
    metric: UsedCommandMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    command = metric["command"]
    passed = any(
        command in _invoked_commands(shell_command)
        for shell_command in evidence.shell_commands
    )
    rationale = (
        f"observed command '{command}'"
        if passed
        else f"did not observe command '{command}'"
    )
    return passed, rationale


def _evaluate_all_commands_prefixed(
    metric: AllShellCommandsPrefixedMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    prefix = metric["prefix"]
    segments = _all_segments(evidence.shell_commands)
    passed = bool(segments) and all(
        _first_executable(segment) == prefix for segment in segments
    )
    rationale = (
        f"all {len(evidence.shell_commands)} shell commands used prefix '{prefix}'"
        if passed
        else f"not every shell command used prefix '{prefix}'"
    )
    return passed, rationale


def _evaluate_command_prefix_rate(
    metric: ShellCommandPrefixRateMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    prefix = metric["prefix"]
    segments = _all_segments(evidence.shell_commands)
    prefixed_segment_count = sum(
        _first_executable(segment) == prefix for segment in segments
    )
    rate = prefixed_segment_count / len(segments) * 100 if segments else 0.0
    rationale = (
        f"{prefixed_segment_count} of {len(segments)} shell command "
        f"segments used prefix '{prefix}'"
    )
    return rate, rationale


def _evaluate_command_count(
    _metric: CommonMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    count = len(evidence.shell_commands)
    return count, f"observed {count} shell commands"


def _evaluate_evidence_count(
    metric: EvidenceCountMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    evidence_type = metric["evidence_type"]
    observed_count = sum(
        event.get("evidence_type") == evidence_type for event in evidence.events
    )
    minimum = metric.get("minimum", 0)
    maximum = metric.get("maximum")
    passed = observed_count >= minimum and (
        maximum is None or observed_count <= maximum
    )
    expected_range = (
        f"{minimum} or more" if maximum is None else f"{minimum} through {maximum}"
    )
    rationale = (
        f"observed {observed_count} '{evidence_type}' events; "
        f"expected {expected_range}"
    )
    return passed, rationale


def _evaluate_evidence_requirements(
    metric: EvidenceRequirementsPercentMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    observed_evidence_types = tuple(
        str(event.get("evidence_type")) for event in evidence.events
    )
    required_evidence_types = tuple(metric.get("required_evidence_types", ()))
    forbidden_evidence_types = tuple(metric.get("forbidden_evidence_types", ()))
    opportunities = (
        *(
            evidence_type in observed_evidence_types
            for evidence_type in required_evidence_types
        ),
        *(
            evidence_type not in observed_evidence_types
            for evidence_type in forbidden_evidence_types
        ),
    )
    if not opportunities:
        return None
    matched_count = sum(opportunities)
    misses = (
        *(
            evidence_type
            for evidence_type in required_evidence_types
            if evidence_type not in observed_evidence_types
        ),
        *(
            f"no {evidence_type}"
            for evidence_type in forbidden_evidence_types
            if evidence_type in observed_evidence_types
        ),
    )
    rationale = f"matched {matched_count} of {len(opportunities)} evidence requirements"
    if misses:
        rationale += f"; missed: {', '.join(misses)}"
    return matched_count / len(opportunities) * 100, rationale


def _evaluate_just_usage(
    metric: PolicyMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    direct_commands = tuple(metric.get("direct_commands", ()))
    just_recipes = tuple(metric.get("just_recipes", ()))
    opportunities = tuple(
        segment
        for command in evidence.shell_commands
        for segment in shell_segments(command)
        if _matches_command_or_recipe(segment, direct_commands, just_recipes)
    )
    if not opportunities:
        return None
    matched_count = sum(
        _invokes_just_recipe(segment, just_recipes) for segment in opportunities
    )
    rationale = (
        f"used just for {matched_count} of {len(opportunities)} "
        "mapped command opportunities"
    )
    return matched_count / len(opportunities) * 100, rationale


def _evaluate_preferred_search(
    metric: PolicyMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    accepted_tools = tuple(metric.get("accepted_search_tools", ()))
    if not accepted_tools:
        return None
    observed_tools = _observed_tool_names(evidence.events, evidence.shell_commands)
    matched_tools = tuple(tool for tool in accepted_tools if tool in observed_tools)
    missing = tuple(tool for tool in accepted_tools if tool not in observed_tools)
    rationale = (
        f"used {len(matched_tools)} of {len(accepted_tools)} preferred search classes"
    )
    if missing:
        rationale += f"; missing: {', '.join(missing)}"
    return len(matched_tools) / len(accepted_tools) * 100, rationale


def _evaluate_debug_unit_tests(
    metric: PolicyMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    required_commands = tuple(metric.get("relevant_test_commands", ()))
    if not required_commands:
        return None
    completed_commands = tuple(
        command
        for command in evidence.shell_commands
        if any(pattern in command for pattern in required_commands)
    )
    matched_count = sum(
        any(pattern in command for command in completed_commands)
        for pattern in required_commands
    )
    rationale = (
        f"completed {matched_count} of {len(required_commands)} "
        "relevant test commands"
    )
    return matched_count / len(required_commands) * 100, rationale


def _evaluate_plan_tracking(
    _metric: CommonMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    observed = any(
        event.get("evidence_type") == "agent.plan" for event in evidence.events
    )
    rationale = (
        "observed CLI plan tracking"
        if observed
        else "did not observe CLI plan tracking"
    )
    return (100.0 if observed else 0.0), rationale


def _evaluate_final_verify(
    _metric: CommonMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    return score_final_verify(evidence.events)


def _evaluate_tdd_appropriate(
    metric: PolicyMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    return score_tdd_sequence(
        evidence.events,
        tuple(metric.get("relevant_test_commands", ())),
        str(metric.get("tdd", "inapplicable")),
    )


def _evaluate_branch_before_changes(
    _metric: CommonMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    return score_branch_before_changes(evidence.events)


def _evaluate_worktree_lifecycle(
    _metric: CommonMetric,
    evidence: ExecutionEvidence,
) -> ScoredMetric:
    return score_worktree_lifecycle(evidence.events)


EXECUTION_EVALUATORS = {
    "used-command": _evaluate_used_command,
    "all-shell-commands-prefixed": _evaluate_all_commands_prefixed,
    "shell-command-prefix-rate": _evaluate_command_prefix_rate,
    "shell-command-count": _evaluate_command_count,
    "evidence-count": _evaluate_evidence_count,
    "evidence-requirements-percent": _evaluate_evidence_requirements,
    "just-usage-percent": _evaluate_just_usage,
    "preferred-search-percent": _evaluate_preferred_search,
    "debug-unit-tests-percent": _evaluate_debug_unit_tests,
    "plan-tracking-percent": _evaluate_plan_tracking,
    "final-verify-percent": _evaluate_final_verify,
    "tdd-appropriate-percent": _evaluate_tdd_appropriate,
    "branch-before-changes-percent": _evaluate_branch_before_changes,
    "worktree-lifecycle-percent": _evaluate_worktree_lifecycle,
}


def _all_segments(
    shell_commands: tuple[str, ...],
) -> tuple[tuple[str, ...], ...]:
    return tuple(
        segment
        for shell_command in shell_commands
        for segment in shell_segments(shell_command)
    )


def _first_executable(segment: tuple[str, ...]) -> str | None:
    """Return the executable token after leading environment assignments."""
    index = executable_index(segment)
    return os.path.basename(segment[index]) if index is not None else None


def _invoked_commands(command: str) -> tuple[str, ...]:
    """Return executable positions, including commands inside shell wrappers."""
    invoked_commands = []
    for segment in shell_segments(command):
        command_index = executable_index(segment)
        if command_index is None:
            continue
        executable = os.path.basename(segment[command_index])
        invoked_commands.append(executable)
        delegated_index = command_index + 1 if executable == "rtk" else command_index
        if delegated_index >= len(segment):
            continue
        delegated_command = os.path.basename(segment[delegated_index])
        if executable == "rtk":
            invoked_commands.append(delegated_command)
        if delegated_command not in {"bash", "sh", "zsh"}:
            continue
        shell_arguments = segment[delegated_index + 1 :]
        for flag in ("-c", "-lc"):
            if flag not in shell_arguments:
                continue
            command_index = shell_arguments.index(flag) + 1
            if command_index < len(shell_arguments):
                invoked_commands.extend(
                    _invoked_commands(shell_arguments[command_index])
                )
            break
    return tuple(invoked_commands)


def _matches_command_or_recipe(
    segment: tuple[str, ...],
    direct_commands: tuple[str, ...],
    just_recipes: tuple[str, ...],
) -> bool:
    rendered = " ".join(segment)
    return any(
        command in rendered for command in direct_commands
    ) or _invokes_just_recipe(segment, just_recipes)


def _invokes_just_recipe(segment: tuple[str, ...], recipes: tuple[str, ...]) -> bool:
    tokens = tuple(os.path.basename(token) for token in segment)
    return "just" in tokens and any(recipe in segment for recipe in recipes)


def _observed_tool_names(
    events: tuple[dict[str, Any], ...], shell_commands: tuple[str, ...]
) -> set[str]:
    names = {str(event.get("name", "")).lower() for event in events}
    rendered = "\n".join(shell_commands).lower()
    tool_classes = {
        "lsp": ("lsp", "workspaceSymbol", "findReferences", "goToDefinition"),
        "structural": ("ast-grep", " sg ", "tree-sitter", "semgrep"),
        "text": ("rg ", "grep "),
    }
    return names | {
        class_name
        for class_name, markers in tool_classes.items()
        if any(marker.lower() in rendered for marker in markers)
    }
