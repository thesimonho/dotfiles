"""Ordered provider compute ladders and relative subagent scoring."""

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class ComputeLevel:
    """One model and effort position from least to most capable."""

    model: str
    effort: str


COMPUTE_LADDERS = {
    "codex": (
        ComputeLevel("gpt-5.6-terra", "low"),
        ComputeLevel("gpt-5.6-terra", "medium"),
        ComputeLevel("gpt-5.6-terra", "high"),
        ComputeLevel("gpt-5.6-luna", "low"),
        ComputeLevel("gpt-5.6-luna", "medium"),
        ComputeLevel("gpt-5.6-luna", "high"),
        ComputeLevel("gpt-5.6-sol", "low"),
        ComputeLevel("gpt-5.6-sol", "medium"),
        ComputeLevel("gpt-5.6-sol", "high"),
    ),
    "claude": (
        ComputeLevel("haiku", "low"),
        ComputeLevel("haiku", "medium"),
        ComputeLevel("haiku", "high"),
        ComputeLevel("sonnet", "low"),
        ComputeLevel("sonnet", "medium"),
        ComputeLevel("sonnet", "high"),
        ComputeLevel("opus", "low"),
        ComputeLevel("opus", "medium"),
        ComputeLevel("opus", "high"),
        ComputeLevel("fable", "low"),
        ComputeLevel("fable", "medium"),
        ComputeLevel("fable", "high"),
    ),
}


def validate_compute_selection_baseline(
    profile: str,
    model: str,
    effort: str,
) -> None:
    """Require a known parent with both cheaper and stronger ladder positions."""
    ladder = _ladder(profile)
    parent_position = _exact_position(ladder, model, effort)
    if parent_position == 0 or parent_position == len(ladder) - 1:
        raise ValueError(
            f"compute-selection case requires room around baseline: {model}:{effort}"
        )


def score_compute_selection(
    events: tuple[dict[str, Any], ...],
    profile: str,
    parent_model: str,
    parent_effort: str,
) -> tuple[float, str]:
    """Score one cheaper delegation and one stronger escalation relative to parent."""
    ladder = _ladder(profile)
    parent_position = _exact_position(ladder, parent_model, parent_effort)
    classified_selections = tuple(
        classified_selection
        for event in events
        if event.get("evidence_type") == "agent.model-selection"
        and isinstance((attributes := event.get("attributes")), dict)
        if (
            classified_selection := _classified_selection(
                ladder,
                parent_position,
                attributes,
            )
        )
        is not None
    )
    expected = {
        ("lightweight", "delegation"),
        ("demanding", "escalation"),
    }
    matched = len(expected.intersection(classified_selections))
    observed = ", ".join(
        f"{task}:{relation}" for task, relation in classified_selections
    )
    return matched * 50.0, f"observed task selections: {observed or 'none'}"


def _ladder(profile: str) -> tuple[ComputeLevel, ...]:
    ladder = COMPUTE_LADDERS.get(profile)
    if ladder is None:
        raise ValueError(f"no compute ladder for agent profile: {profile}")
    return ladder


def _exact_position(
    ladder: tuple[ComputeLevel, ...],
    model: str,
    effort: str,
) -> int:
    selection = ComputeLevel(model, effort)
    if selection not in ladder:
        raise ValueError(f"compute selection is absent from ladder: {model}:{effort}")
    return ladder.index(selection)


def _classified_selection(
    ladder: tuple[ComputeLevel, ...],
    parent_position: int,
    attributes: dict[str, object],
) -> tuple[str, str] | None:
    task_class = _task_class(attributes)
    model = attributes.get("model")
    effort = attributes.get("reasoning_effort")
    if task_class is None or not isinstance(model, str):
        return None
    positions = tuple(
        index
        for index, level in enumerate(ladder)
        if level.model == model and (effort is None or level.effort == effort)
    )
    if positions and max(positions) < parent_position:
        return task_class, "delegation"
    if positions and min(positions) > parent_position:
        return task_class, "escalation"
    edge_relation = _model_band_edge_relation(
        ladder,
        parent_model=ladder[parent_position].model,
        selected_model=model,
        selected_effort=effort,
        task_class=task_class,
    )
    if edge_relation is not None:
        return task_class, edge_relation
    return task_class, "equal-or-ambiguous"


def _model_band_edge_relation(
    ladder: tuple[ComputeLevel, ...],
    *,
    parent_model: str,
    selected_model: str,
    selected_effort: object,
    task_class: str,
) -> str | None:
    """Credit a same-model choice when no further model band exists.

    Claude does not expose child effort, so when the parent already runs the
    strongest model, requesting that model for demanding work is the maximal
    expressible escalation; the same fairness applies to the weakest model
    for lightweight work. Effort-aware providers keep the strict rule.
    """
    if selected_effort is not None or selected_model != parent_model:
        return None
    model_order = tuple(dict.fromkeys(level.model for level in ladder))
    if task_class == "demanding" and parent_model == model_order[-1]:
        return "escalation"
    if task_class == "lightweight" and parent_model == model_order[0]:
        return "delegation"
    return None


def _task_class(attributes: dict[str, object]) -> str | None:
    agent_role = attributes.get("agent") or attributes.get("subagent_type")
    if not isinstance(agent_role, str):
        return None
    normalized_role = agent_role.lower()
    if normalized_role in {"explore", "explorer"}:
        return "lightweight"
    if normalized_role in {"default", "general-purpose"}:
        return "demanding"
    return None
