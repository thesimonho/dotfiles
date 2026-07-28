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
    requires_complete_task: NotRequired[bool]


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


class OutputCompletionMetric(CommonMetric):
    """Classify task completion from deterministic response requirements."""

    evaluator: Literal["output-completion"]
    required_mentions: tuple[str, ...]


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


class EvidenceCountMetric(CommonMetric):
    """Require normalized semantic evidence to occur within declared bounds."""

    evaluator: Literal["evidence-count"]
    evidence_type: EvidenceRequirement
    minimum: NotRequired[int]
    maximum: NotRequired[int]


class EvidenceRequirementsPercentMetric(CommonMetric):
    """Score required and forbidden semantic evidence opportunities."""

    evaluator: Literal["evidence-requirements-percent"]
    required_evidence_types: NotRequired[tuple[EvidenceRequirement, ...]]
    forbidden_evidence_types: NotRequired[tuple[EvidenceRequirement, ...]]


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


class WorkspaceCompletionMetric(CommonMetric):
    """Classify deterministic workspace task completion."""

    evaluator: Literal["workspace-completion"]


class RequiredDocumentationUpdatesMetric(CommonMetric):
    """Score declared documentation obligations satisfied in the workspace."""

    evaluator: Literal["required-documentation-updates-percent"]


class PolicyMetric(CommonMetric, total=False):
    """Declarative policy metric evaluated from ordered events or final state."""

    evaluator: Literal[
        "just-usage-percent",
        "preferred-search-percent",
        "codemap-first-percent",
        "tdd-appropriate-percent",
        "debug-unit-tests-percent",
        "debug-logs-count",
        "final-verify-percent",
        "plan-tracking-percent",
        "large-plan-file-percent",
        "plan-file-reference-count",
        "conventional-commits-percent",
        "branch-before-changes-percent",
        "worktree-lifecycle-percent",
        "function-limits-percent",
        "hardcoded-secrets-count",
        "critical-response-percent",
        "subagent-compute-selection-percent",
    ]
    direct_commands: tuple[str, ...]
    just_recipes: tuple[str, ...]
    accepted_search_tools: tuple[str, ...]
    relevant_test_commands: tuple[str, ...]
    tdd: Literal["expected", "not-expected", "inapplicable"]
    allowed_commit_types: tuple[str, ...]
    critical_mentions: tuple[str, ...]
    critical_path: str
    expected_selections: tuple[str, ...]


type ResponseMetric = (
    OutputContainsMetric
    | OutputContainsAllMetric
    | OutputQualityMetric
    | OutputCompletionMetric
)
type ExecutionMetric = (
    AllShellCommandsPrefixedMetric
    | ShellCommandPrefixRateMetric
    | UsedCommandMetric
    | ShellCommandCountMetric
    | EvidenceCountMetric
    | EvidenceRequirementsPercentMetric
)
type WorkspaceMetric = (
    NegativeConstraintsFollowedMetric
    | ProtectedResourcesPreservedMetric
    | UnnecessaryChangeCountMetric
    | BlastRadiusSeverityMetric
    | WorkspaceOutcomeMetric
    | WorkspaceCompletionMetric
    | RequiredDocumentationUpdatesMetric
)
type EvaluationMetric = (
    ResponseMetric | ExecutionMetric | WorkspaceMetric | PolicyMetric
)


class EvaluationCase(TypedDict):
    """One prompt and the independently applicable metrics it requests."""

    case_id: str
    case_name: str
    category: str
    prompt: str
    required_evidence: NotRequired[tuple[EvidenceRequirement, ...]]
    required_observed_evidence: NotRequired[tuple[EvidenceRequirement, ...]]
    workspace: NotRequired[WorkspaceSpec]
    metrics: tuple[EvaluationMetric, ...]
    agent_profiles: NotRequired[tuple[Literal["codex", "claude"], ...]]
