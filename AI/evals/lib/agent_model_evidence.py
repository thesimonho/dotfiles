"""Provider-specific model-selection evidence contracts."""

from dataclasses import dataclass
from typing import Any, Protocol


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


def claude_resolved_child_models(
    events: tuple[dict[str, Any], ...],
) -> dict[str, tuple[str, ...]]:
    """Map each Agent call to the models its child messages actually ran on.

    Subagent activity is forwarded into the parent stream as assistant events
    whose parent_tool_use_id is the spawning Agent call, and each carries the
    resolved child model rather than the requested alias.
    """
    resolved_models: dict[str, list[str]] = {}
    for event in events:
        parent_tool_use_id = event.get("parent_tool_use_id")
        if event.get("type") != "assistant" or not isinstance(parent_tool_use_id, str):
            continue
        message = event.get("message")
        model = message.get("model") if isinstance(message, dict) else None
        if not isinstance(model, str):
            continue
        observed_models = resolved_models.setdefault(parent_tool_use_id, [])
        if model not in observed_models:
            observed_models.append(model)
    return {
        parent_tool_use_id: tuple(models)
        for parent_tool_use_id, models in resolved_models.items()
    }


def claude_invocation_model_selections(
    events: tuple[AgentEventLike, ...],
    resolved_models_by_tool_use_id: dict[str, tuple[str, ...]] | None = None,
) -> tuple[ClaudeInvocationModelSelection, ...]:
    """Extract explicit models after higher-priority environment filtering.

    The requested model stays authoritative for scoring; the resolved child
    model observed in forwarded subagent messages is attached as diagnostic
    evidence so a served-model mismatch is inspectable on the trace.
    """
    resolved_models = resolved_models_by_tool_use_id or {}
    selections = []
    for event in events:
        attributes = dict(event.attributes)
        model = attributes.get("model")
        if event.evidence_type != "agent.spawn" or not isinstance(model, str):
            continue
        safe_attributes = [
            (name, attributes[name])
            for name in ("model", "name", "subagent_type", "tool_use_id")
            if name in attributes
        ]
        tool_use_id = attributes.get("tool_use_id")
        if isinstance(tool_use_id, str) and tool_use_id in resolved_models:
            safe_attributes.append(
                ("resolved_model", ",".join(resolved_models[tool_use_id]))
            )
        selections.append(
            ClaudeInvocationModelSelection(event.status, tuple(safe_attributes))
        )
    return tuple(selections)
