"""Cross-provider scoring for delegated model and effort selection."""

from collections.abc import Mapping
from typing import Any


def score_compute_selection(
    events: tuple[dict[str, Any], ...],
    acceptable_selection_sets: tuple[tuple[str, ...], ...],
) -> tuple[float, str]:
    """Return the best match across provider-specific acceptable selections."""
    observed = tuple(
        _selection_from_attributes(attributes)
        for event in events
        if event.get("evidence_type") == "agent.model-selection"
        and isinstance((attributes := event.get("attributes")), dict)
    )
    results = tuple(
        _score_expected_set(observed, expected)
        for expected in acceptable_selection_sets
        if expected
    )
    if not results:
        return 0.0, "no acceptable subagent compute selections configured"
    matched, expected = max(results, key=lambda result: result[0] / len(result[1]))
    percent = matched / len(expected) * 100
    rationale = f"resolved {matched} of {len(expected)} acceptable selections"
    missing = tuple(
        selection
        for selection in expected
        if observed.count(selection) < expected.count(selection)
    )
    if missing:
        rationale += f"; missing: {', '.join(dict.fromkeys(missing))}"
    return percent, rationale


def _selection_from_attributes(attributes: Mapping[str, object]) -> str:
    model = attributes.get("model")
    effort = attributes.get("reasoning_effort")
    return f"{model}:{effort}" if effort else str(model)


def _score_expected_set(
    observed: tuple[str, ...],
    expected: tuple[str, ...],
) -> tuple[int, tuple[str, ...]]:
    remaining = list(observed)
    matched = 0
    for selection in expected:
        if selection not in remaining:
            continue
        remaining.remove(selection)
        matched += 1
    return matched, expected
