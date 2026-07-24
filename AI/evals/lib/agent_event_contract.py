"""Semantic evidence contracts shared by eval cases and CLI parsers."""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import asdict, dataclass
from typing import Literal, cast

type EvidenceRequirement = Literal[
    "agent.message",
    "agent.definition-canary",
    "agent.model-selection",
    "agent.spawn",
    "token.usage",
    "tool.file-change",
    "tool.mcp",
    "tool.shell",
    "tool.web-search",
]

SUPPORTED_EVIDENCE_BY_PROFILE: dict[str, frozenset[EvidenceRequirement]] = {
    "codex": frozenset(
        {
            "agent.message",
            "agent.definition-canary",
            "agent.spawn",
            "token.usage",
            "tool.file-change",
            "tool.mcp",
            "tool.shell",
            "tool.web-search",
        }
    ),
    "claude": frozenset(
        {
            "agent.definition-canary",
            "agent.message",
            "agent.model-selection",
            "agent.spawn",
            "token.usage",
            "tool.file-change",
            "tool.mcp",
            "tool.shell",
            "tool.web-search",
        }
    ),
}


@dataclass(frozen=True)
class AgentEventCoverage:
    """Parser disposition for every distinct event shape in one CLI stream."""

    observed_event_types: tuple[str, ...]
    normalized_evidence_types: tuple[str, ...]
    intentionally_ignored_event_types: tuple[str, ...]
    unknown_event_types: tuple[str, ...]

    def to_dict(self) -> dict[str, object]:
        """Render coverage as stable JSON-compatible evidence."""
        return asdict(self)


def unobserved_evidence_requirements(
    required_evidence: Iterable[str],
    observed_evidence: Iterable[str],
) -> tuple[str, ...]:
    """Return must-observe evidence absent from one normalized event stream."""
    return tuple(sorted(set(required_evidence) - set(observed_evidence)))


def unsupported_evidence_requirements(
    profile: str,
    requirements: tuple[EvidenceRequirement, ...],
) -> tuple[EvidenceRequirement, ...]:
    """Return requirements the selected CLI parser cannot prove."""
    supported_evidence = SUPPORTED_EVIDENCE_BY_PROFILE.get(profile)
    if supported_evidence is None:
        raise ValueError(f"unsupported agent profile: {profile}")
    return tuple(
        requirement
        for requirement in requirements
        if requirement not in supported_evidence
    )


def validate_case_evidence_requirements(
    profile: str,
    cases: tuple[Mapping[str, object], ...],
) -> None:
    """Reject missing, duplicate, or unsupported requirements before execution."""
    unsupported_by_case: dict[str, tuple[EvidenceRequirement, ...]] = {}
    for case in cases:
        case_id = case.get("case_id")
        requirements = case.get("required_evidence")
        observed_requirements = case.get("required_observed_evidence")
        if not isinstance(case_id, str):
            raise TypeError("evaluation case must have a string case_id")
        if not isinstance(requirements, tuple) or not requirements:
            raise ValueError(
                f"case {case_id} must declare at least one evidence requirement"
            )
        if not all(isinstance(requirement, str) for requirement in requirements):
            raise TypeError(f"case {case_id} evidence requirements must be strings")
        if not isinstance(observed_requirements, tuple):
            raise ValueError(f"case {case_id} must declare required_observed_evidence")
        if not all(
            isinstance(requirement, str) for requirement in observed_requirements
        ):
            raise TypeError(
                f"case {case_id} observed evidence requirements must be strings"
            )
        typed_requirements = cast(tuple[EvidenceRequirement, ...], requirements)
        typed_observed_requirements = cast(
            tuple[EvidenceRequirement, ...],
            observed_requirements,
        )
        if len(typed_requirements) != len(set(typed_requirements)):
            raise ValueError(f"case {case_id} declares duplicate evidence requirements")
        if len(typed_observed_requirements) != len(set(typed_observed_requirements)):
            raise ValueError(
                f"case {case_id} declares duplicate observed evidence requirements"
            )
        undeclared_observed_requirements = set(typed_observed_requirements) - set(
            typed_requirements
        )
        if undeclared_observed_requirements:
            names = ", ".join(sorted(undeclared_observed_requirements))
            raise ValueError(
                f"case {case_id} must include observed requirements in "
                f"required_evidence: {names}"
            )
        unsupported = unsupported_evidence_requirements(profile, typed_requirements)
        if unsupported:
            unsupported_by_case[case_id] = unsupported
    if not unsupported_by_case:
        return
    details = "; ".join(
        f"{case_id}: {', '.join(requirements)}"
        for case_id, requirements in unsupported_by_case.items()
    )
    raise RuntimeError(
        f"{profile} parser cannot satisfy case evidence requirements: {details}"
    )
