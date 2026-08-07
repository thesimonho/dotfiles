"""Instruction coverage and cost-aware evaluation campaign planning."""

from dataclasses import dataclass
from typing import Literal

from configuration_components import ConfigComponent
from evaluation_case import EvaluationCase

type CoverageMaturity = Literal["planned", "active", "proven"]


@dataclass(frozen=True)
class InstructionCoverage:
    """Connect one instruction hypothesis to applicable evaluation cases."""

    component_id: str
    hypothesis: str
    maturity: CoverageMaturity
    case_ids: tuple[str, ...]
    enabled: bool = True


@dataclass(frozen=True)
class EvaluationCampaignPlan:
    """Projected CLI usage for a component comparison campaign."""

    component_id: str
    hypothesis: str
    maturity: CoverageMaturity
    case_ids: tuple[str, ...]
    repetitions: int
    comparison_pairs: int
    agent_under_test_invocations: int
    judge_invocations: int

    @property
    def total_cli_invocations(self) -> int:
        """Return all agent-under-test and judge CLI invocations."""
        return self.agent_under_test_invocations + self.judge_invocations


def format_campaign_plan(
    plan: EvaluationCampaignPlan,
    *,
    agent_profile: str,
) -> str:
    """Render projected usage without starting an agent or MLflow run."""
    case_lines = "\n".join(f"  - {case_id}" for case_id in plan.case_ids)
    return "\n".join(
        (
            f"agent profile: {agent_profile}",
            f"component: {plan.component_id}",
            f"maturity: {plan.maturity}",
            f"hypothesis: {plan.hypothesis}",
            f"repetitions per case: {plan.repetitions}",
            f"comparison pairs: {plan.comparison_pairs}",
            f"agent-under-test invocations: {plan.agent_under_test_invocations}",
            f"judge invocations: {plan.judge_invocations}",
            f"total CLI invocations: {plan.total_cli_invocations}",
            "cases:",
            case_lines or "  (none)",
        )
    )


def plan_instruction_campaign(
    component_id: str,
    *,
    repetitions: int,
    coverage: tuple[InstructionCoverage, ...],
    cases: tuple[EvaluationCase, ...],
    agent_profile: str | None = None,
    known_component_ids: tuple[str, ...] | None = None,
) -> EvaluationCampaignPlan:
    """Resolve applicable cases and project paired comparison usage."""
    if repetitions < 1:
        raise ValueError("campaign repetitions must be at least one")

    known_case_ids = tuple(case["case_id"] for case in cases)
    validate_coverage_catalog(
        coverage,
        known_case_ids=known_case_ids,
        known_component_ids=known_component_ids,
    )
    matching_entries = tuple(
        entry for entry in coverage if entry.component_id == component_id
    )
    if not matching_entries:
        raise ValueError(f"instruction component has no coverage entry: {component_id}")

    entry = matching_entries[0]
    if not entry.enabled:
        raise ValueError(
            f"coverage for {component_id} is disabled; enable it in catalog.toml"
        )
    cases_by_id = {case["case_id"]: case for case in cases}
    selected_cases = tuple(
        cases_by_id[case_id]
        for case_id in entry.case_ids
        if agent_profile is None
        or agent_profile
        in cases_by_id[case_id].get("agent_profiles", ("codex", "claude"))
    )
    selected_case_ids = tuple(case["case_id"] for case in selected_cases)
    comparison_pairs = len(selected_cases) * repetitions
    judged_case_count = sum(
        any(metric["evaluator"] == "output-quality" for metric in case["metrics"])
        for case in selected_cases
    )
    return EvaluationCampaignPlan(
        component_id=entry.component_id,
        hypothesis=entry.hypothesis,
        maturity=entry.maturity,
        case_ids=selected_case_ids,
        repetitions=repetitions,
        comparison_pairs=comparison_pairs,
        agent_under_test_invocations=comparison_pairs * 2,
        judge_invocations=judged_case_count * repetitions * 2,
    )


def validate_coverage_catalog(
    coverage: tuple[InstructionCoverage, ...],
    *,
    known_case_ids: tuple[str, ...],
    known_component_ids: tuple[str, ...] | None = None,
) -> None:
    """Reject coverage entries that cannot resolve to executable cases."""
    if known_component_ids is not None:
        stale_component_ids = tuple(
            entry.component_id
            for entry in coverage
            if entry.component_id not in known_component_ids
        )
        if stale_component_ids:
            formatted_component_ids = ", ".join(stale_component_ids)
            raise ValueError(
                "coverage entries reference components that are no longer "
                f"monitored; remove them from coverage_catalog.py: "
                f"{formatted_component_ids}"
            )
    known_maturities = {"planned", "active", "proven"}
    invalid_maturities = tuple(
        f"{entry.component_id}: {entry.maturity}"
        for entry in coverage
        if entry.maturity not in known_maturities
    )
    if invalid_maturities:
        raise ValueError(
            f"unknown coverage maturity values: {', '.join(invalid_maturities)}"
        )
    component_ids = tuple(entry.component_id for entry in coverage)
    duplicate_component_ids = {
        component_id
        for component_id in component_ids
        if component_ids.count(component_id) > 1
    }
    if duplicate_component_ids:
        formatted_component_ids = ", ".join(sorted(duplicate_component_ids))
        raise ValueError(
            f"duplicate instruction coverage components: {formatted_component_ids}"
        )

    uncovered_active_components = tuple(
        entry.component_id
        for entry in coverage
        if entry.maturity in {"active", "proven"} and not entry.case_ids
    )
    if uncovered_active_components:
        formatted_component_ids = ", ".join(uncovered_active_components)
        raise ValueError(
            f"active instruction coverage requires cases: {formatted_component_ids}"
        )

    for entry in coverage:
        duplicate_case_ids = {
            case_id for case_id in entry.case_ids if entry.case_ids.count(case_id) > 1
        }
        if duplicate_case_ids:
            formatted_case_ids = ", ".join(sorted(duplicate_case_ids))
            raise ValueError(
                f"duplicate cases for {entry.component_id}: {formatted_case_ids}"
            )

    unknown_case_ids = {
        case_id
        for entry in coverage
        for case_id in entry.case_ids
        if case_id not in known_case_ids
    }
    if unknown_case_ids:
        formatted_case_ids = ", ".join(sorted(unknown_case_ids))
        raise ValueError(f"unknown evaluation case IDs: {formatted_case_ids}")


def format_coverage_report(
    coverage: tuple[InstructionCoverage, ...],
    components: tuple[ConfigComponent, ...],
    *,
    known_case_ids: tuple[str, ...],
) -> str:
    """Render every monitored component's tracking and coverage state.

    Discovery is the source of truth: components appear here the moment their
    file exists, so adding or removing fragments, agents, or skills never
    requires manual list maintenance. Instruction components without a
    coverage entry are tracked but unmeasured until they earn cases.
    """
    validate_coverage_catalog(
        coverage,
        known_case_ids=known_case_ids,
        known_component_ids=tuple(
            component.component_id for component in components
        ),
    )
    coverage_by_component_id = {entry.component_id: entry for entry in coverage}
    lines = []
    for kind, heading in (
        ("instruction", "instruction components"),
        ("agent", "agent components"),
        ("skill", "skill components"),
    ):
        kind_components = tuple(
            component
            for component in components
            if component.component_id.startswith(f"{kind}/")
        )
        lines.append(f"{heading} ({len(kind_components)}):")
        if not kind_components:
            lines.append("  (none)")
            continue
        for component in kind_components:
            entry = coverage_by_component_id.get(component.component_id)
            if kind != "instruction":
                lines.append(f"  {component.component_id}: tracked")
            elif entry is None:
                lines.append(
                    f"  {component.component_id}: tracked, unmeasured "
                    "(no coverage entry)"
                )
            else:
                enabled_note = "" if entry.enabled else ", disabled"
                lines.append(
                    f"  {component.component_id}: {entry.maturity}, "
                    f"{len(entry.case_ids)} case(s){enabled_note}"
                )
    return "\n".join(lines)
