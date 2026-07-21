"""Typed contracts for reusable agent evaluation metrics and cases."""

from typing import Literal, TypedDict


class CommonMetric(TypedDict):
    """Fields shared by every independently reported evaluation metric."""

    name: str


class OutputContainsMetric(CommonMetric):
    """Deterministically require text in the final response."""

    evaluator: Literal["output-contains"]
    expected_mention: str


class OutputQualityMetric(CommonMetric):
    """Judge final-response quality against a natural-language rubric."""

    evaluator: Literal["output-quality"]
    rubric: str


class OutputContainsAllMetric(CommonMetric):
    """Deterministically require several values in the final response."""

    evaluator: Literal["output-contains-all"]
    expected_mentions: tuple[str, ...]


class AllShellCommandsPrefixedMetric(CommonMetric):
    """Require every observed shell command to start with one prefix."""

    evaluator: Literal["all-shell-commands-prefixed"]
    prefix: str


class UsedCommandMetric(CommonMetric):
    """Require at least one observed shell command to invoke a command."""

    evaluator: Literal["used-command"]
    command: str


class ShellCommandCountMetric(CommonMetric):
    """Report the number of shell commands without imposing a threshold."""

    evaluator: Literal["shell-command-count"]


type ResponseMetric = (
    OutputContainsMetric | OutputContainsAllMetric | OutputQualityMetric
)
type ExecutionMetric = (
    AllShellCommandsPrefixedMetric | UsedCommandMetric | ShellCommandCountMetric
)
type EvaluationMetric = ResponseMetric | ExecutionMetric


class EvaluationCase(TypedDict):
    """One prompt and the independently applicable metrics it requests."""

    case_id: str
    category: str
    prompt: str
    metrics: tuple[EvaluationMetric, ...]
