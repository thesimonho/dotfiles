"""Typed contracts for reusable agent evaluation metrics and cases."""

from typing import Literal, NotRequired, TypedDict

from agent_event_contract import EvidenceRequirement


class WorkspaceSpec(TypedDict):
    """Agent-visible environment selector without hidden validator policy."""

    environment: str
    scenario: str
    access: Literal["read-only", "workspace-write"]


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


class ShellCommandPrefixRateMetric(CommonMetric):
    """Report the fraction of observed command segments using one prefix."""

    evaluator: Literal["shell-command-prefix-rate"]
    prefix: str


class UsedCommandMetric(CommonMetric):
    """Require at least one observed shell command to invoke a command."""

    evaluator: Literal["used-command"]
    command: str


class ShellCommandCountMetric(CommonMetric):
    """Report the number of shell commands without imposing a threshold."""

    evaluator: Literal["shell-command-count"]


class NegativeConstraintsFollowedMetric(CommonMetric):
    """Require all hidden scenario prohibitions to remain unviolated."""

    evaluator: Literal["negative-constraints-followed"]


class ProtectedResourcesPreservedMetric(CommonMetric):
    """Require consequence-bearing protected paths to remain unchanged."""

    evaluator: Literal["protected-resources-preserved"]


class UnnecessaryChangeCountMetric(CommonMetric):
    """Report agent-attributable changes outside the scenario allowlist."""

    evaluator: Literal["unnecessary-change-count"]


class BlastRadiusSeverityMetric(CommonMetric):
    """Report the highest consequence of an unnecessary action."""

    evaluator: Literal["blast-radius-severity"]


class WorkspaceOutcomeMetric(CommonMetric):
    """Require the scenario's hidden deterministic outcome validator to pass."""

    evaluator: Literal["workspace-outcome"]


type ResponseMetric = (
    OutputContainsMetric | OutputContainsAllMetric | OutputQualityMetric
)
type ExecutionMetric = (
    AllShellCommandsPrefixedMetric
    | ShellCommandPrefixRateMetric
    | UsedCommandMetric
    | ShellCommandCountMetric
)
type WorkspaceMetric = (
    NegativeConstraintsFollowedMetric
    | ProtectedResourcesPreservedMetric
    | UnnecessaryChangeCountMetric
    | BlastRadiusSeverityMetric
    | WorkspaceOutcomeMetric
)
type EvaluationMetric = ResponseMetric | ExecutionMetric | WorkspaceMetric


class EvaluationCase(TypedDict):
    """One prompt and the independently applicable metrics it requests."""

    case_id: str
    category: str
    prompt: str
    required_evidence: NotRequired[tuple[EvidenceRequirement, ...]]
    required_observed_evidence: NotRequired[tuple[EvidenceRequirement, ...]]
    workspace: NotRequired[WorkspaceSpec]
    metrics: tuple[EvaluationMetric, ...]
