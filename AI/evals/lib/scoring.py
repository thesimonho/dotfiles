"""Reusable response and execution-evidence evaluation metrics."""

from dataclasses import dataclass
import os
import shlex
from typing import Any, cast

import agent
from agent_execution_context import AgentExecutionContext
from evaluation_case import EvaluationMetric


@dataclass(frozen=True)
class MetricResult:
    """One independently reportable MLflow metric result."""

    name: str
    value: bool | int | float | str
    rationale: str


def score_output_quality(
    output: str,
    rubric: str,
    context: AgentExecutionContext,
    profile: str = "claude",
) -> tuple[bool, str]:
    """Judge response quality through the selected authenticated agent CLI."""
    judge_prompt = (
        f"Judge whether this output satisfies the rubric below. "
        f"Reply with PASS or FAIL on the first line, followed by one concise "
        f"sentence explaining the verdict.\n\n"
        f"Rubric: {rubric}\nOutput: {output}"
    )
    verdict_raw = agent.run_judge(judge_prompt, context, profile=profile)
    verdict = verdict_raw.strip().splitlines()[0].upper()
    if verdict not in {"PASS", "FAIL"}:
        raise RuntimeError("evaluation judge did not return PASS or FAIL")
    return verdict == "PASS", verdict_raw[:1000]


def score_expected_mention(output: str, expected_mention: str) -> tuple[bool, str]:
    """Check the final response for required text without invoking a judge."""
    passed = expected_mention.lower() in output.lower()
    outcome = "contained" if passed else "did not contain"
    return passed, f"final response {outcome} '{expected_mention}'"


def score_expected_mentions(
    output: str,
    expected_mentions: tuple[str, ...],
) -> tuple[bool, str]:
    """Check that every required value appears in the final response."""
    missing_mentions = [
        mention
        for mention in expected_mentions
        if mention.lower() not in output.lower()
    ]
    if not missing_mentions:
        return True, "final response contained every expected mention"
    return False, f"final response missed: {', '.join(missing_mentions)}"


def score_response_metrics(
    output: str,
    metrics: tuple[EvaluationMetric, ...],
    context: AgentExecutionContext | None,
    profile: str = "claude",
) -> list[MetricResult]:
    """Score only metrics whose evidence is available in the final response."""
    results = []
    for metric in metrics:
        if metric["evaluator"] == "output-contains":
            passed, rationale = score_expected_mention(
                output,
                metric["expected_mention"],
            )
        elif metric["evaluator"] == "output-contains-all":
            passed, rationale = score_expected_mentions(
                output,
                tuple(metric["expected_mentions"]),
            )
        elif metric["evaluator"] == "output-quality":
            if context is None:
                raise ValueError("output-quality metrics require a judge context")
            passed, rationale = score_output_quality(
                output,
                metric["rubric"],
                context,
                profile=profile,
            )
        else:
            continue
        results.append(MetricResult(metric["name"], passed, rationale))
    return results


def score_execution_metrics(
    shell_commands: tuple[str, ...],
    metrics: tuple[EvaluationMetric, ...],
) -> list[MetricResult]:
    """Score metrics whose evidence comes from normalized execution events."""
    results = []
    for metric in metrics:
        if metric["evaluator"] == "used-command":
            command = metric["command"]
            passed = any(
                command in _invoked_commands(shell_command)
                for shell_command in shell_commands
            )
            rationale = (
                f"observed command '{command}'"
                if passed
                else f"did not observe command '{command}'"
            )
        elif metric["evaluator"] == "all-shell-commands-prefixed":
            prefix = metric["prefix"]
            segments = tuple(
                segment
                for shell_command in shell_commands
                for segment in _shell_segments(shell_command)
            )
            passed = bool(segments) and all(
                _first_executable(segment) == prefix for segment in segments
            )
            rationale = (
                f"all {len(shell_commands)} shell commands used prefix '{prefix}'"
                if passed
                else f"not every shell command used prefix '{prefix}'"
            )
        elif metric["evaluator"] == "shell-command-count":
            passed = len(shell_commands)
            rationale = f"observed {passed} shell commands"
        else:
            continue
        results.append(MetricResult(metric["name"], passed, rationale))
    return results


def _shell_segments(command: str) -> tuple[tuple[str, ...], ...]:
    """Split a shell string into simple command segments."""
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars="|&;")
        lexer.whitespace_split = True
        tokens = tuple(lexer)
    except ValueError:
        tokens = tuple(command.split())
    segments = []
    current_segment = []
    for token in tokens:
        if token and all(character in "|&;" for character in token):
            if current_segment:
                segments.append(tuple(current_segment))
                current_segment = []
            continue
        current_segment.append(token)
    if current_segment:
        segments.append(tuple(current_segment))
    return tuple(segments)


def _first_executable(segment: tuple[str, ...]) -> str | None:
    """Return the executable token after leading environment assignments."""
    for token in segment:
        if "=" in token and not token.startswith(("=", "-")):
            continue
        return os.path.basename(token)
    return None


def _invoked_commands(command: str) -> tuple[str, ...]:
    """Return executable positions, including commands inside shell wrappers."""
    invoked_commands = []
    for segment in _shell_segments(command):
        executable_index = next(
            (
                index
                for index, token in enumerate(segment)
                if not ("=" in token and not token.startswith(("=", "-")))
            ),
            None,
        )
        if executable_index is None:
            continue
        executable = os.path.basename(segment[executable_index])
        invoked_commands.append(executable)
        delegated_index = (
            executable_index + 1 if executable == "rtk" else executable_index
        )
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


def metric_from_mapping(value: Any) -> EvaluationMetric:
    """Normalize an MLflow-deserialized metric mapping for typed scoring."""
    if not isinstance(value, dict):
        raise TypeError("evaluation metric must be a mapping")
    return cast(EvaluationMetric, value)
