"""Provider-specific model-selection evidence contracts."""

from dataclasses import dataclass
from typing import Protocol


class AgentEventLike(Protocol):
    """Minimal normalized event surface needed to derive model selection."""

    evidence_type: str
    status: str
    attributes: tuple[tuple[str, object], ...]


@dataclass(frozen=True)
class ClaudeInvocationModelSelection:
    """Explicit model chosen in one Claude Agent-tool invocation."""

    status: str
    attributes: tuple[tuple[str, object], ...]


def claude_invocation_model_selections(
    events: tuple[AgentEventLike, ...],
) -> tuple[ClaudeInvocationModelSelection, ...]:
    """Extract explicit models after higher-priority environment filtering."""
    selections = []
    for event in events:
        attributes = dict(event.attributes)
        model = attributes.get("model")
        if event.evidence_type != "agent.spawn" or not isinstance(model, str):
            continue
        safe_attributes = tuple(
            (name, attributes[name])
            for name in ("model", "name", "subagent_type")
            if name in attributes
        )
        selections.append(ClaudeInvocationModelSelection(event.status, safe_attributes))
    return tuple(selections)
