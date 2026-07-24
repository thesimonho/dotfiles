"""Normalize inspectable execution evidence from agent CLI event streams."""

from __future__ import annotations

import os
import shlex
from dataclasses import asdict, dataclass
from typing import Any, Literal

type EvidenceValue = str | int | float | bool
type AgentEventCategory = Literal["agent", "runtime", "tool"]


@dataclass(frozen=True)
class AgentEvent:
    """One safe, normalized observation from an agent CLI event stream."""

    category: AgentEventCategory
    name: str
    status: str
    attributes: tuple[tuple[str, EvidenceValue], ...] = ()

    def to_dict(self) -> dict[str, object]:
        """Render the event without exposing an arbitrary raw CLI payload."""
        return {
            "category": self.category,
            "name": self.name,
            "status": self.status,
            "attributes": dict(self.attributes),
        }


@dataclass(frozen=True)
class TokenUsage:
    """Provider-aware token counts normalized to comparable dimensions."""

    source: str
    input_tokens: int | None = None
    uncached_input_tokens: int | None = None
    cached_input_tokens: int | None = None
    cache_creation_input_tokens: int | None = None
    output_tokens: int | None = None
    reasoning_output_tokens: int | None = None
    total_tokens: int | None = None

    def to_dict(self) -> dict[str, object]:
        """Render every dimension so unavailable values remain explicit."""
        return asdict(self)

    def available_counts(self) -> dict[str, int]:
        """Return only numeric dimensions suitable for MLflow feedback."""
        usage = asdict(self)
        return {
            name: value
            for name, value in usage.items()
            if name != "source" and isinstance(value, int)
        }


def codex_evidence(
    events: tuple[dict[str, Any], ...],
) -> tuple[tuple[AgentEvent, ...], TokenUsage, tuple[str, ...]]:
    """Normalize Codex JSONL items, turn usage, and any emitted model IDs."""
    completed_items = tuple(
        event["item"]
        for event in events
        if event.get("type") == "item.completed" and isinstance(event.get("item"), dict)
    )
    agent_events = tuple(
        normalized_event
        for item in completed_items
        if (normalized_event := _codex_item_event(item)) is not None
    )
    usage_event = next(
        (
            event
            for event in reversed(events)
            if event.get("type") == "turn.completed"
            and isinstance(event.get("usage"), dict)
        ),
        None,
    )
    token_usage = _codex_token_usage(usage_event["usage"] if usage_event else {})
    model_ids = _model_ids_from_events(events)
    return agent_events, token_usage, model_ids


def claude_evidence(
    events: tuple[dict[str, Any], ...],
    result_event: dict[str, Any],
) -> tuple[tuple[AgentEvent, ...], TokenUsage, tuple[str, ...]]:
    """Normalize Claude tool-use blocks, result usage, and emitted model IDs."""
    tool_results = _claude_tool_results(events)
    agent_events = tuple(
        _claude_tool_event(content, tool_results)
        for event in events
        if event.get("type") == "assistant"
        for content in event.get("message", {}).get("content", [])
        if content.get("type") == "tool_use"
    )
    token_usage = _claude_token_usage(result_event.get("usage", {}))
    model_ids = _claude_model_ids(events, result_event)
    return agent_events, token_usage, model_ids


def normalize_shell_command(command: str) -> str:
    """Remove the CLI's shell launcher while preserving agent-authored syntax."""
    try:
        tokens = shlex.split(command)
    except ValueError:
        return command
    if len(tokens) >= 3 and os.path.basename(tokens[0]) in {"bash", "sh", "zsh"}:
        if tokens[1] in {"-c", "-lc"}:
            return tokens[2]
    return command


def _codex_item_event(item: dict[str, Any]) -> AgentEvent | None:
    item_type = item.get("type")
    if not isinstance(item_type, str):
        return None
    if item_type in {"agent_message", "reasoning", "todo_list"}:
        return None

    name = _codex_item_name(item_type, item)
    category: AgentEventCategory = (
        "agent"
        if "agent" in item_type or "collaboration" in item_type or "collab" in item_type
        else "runtime"
        if item_type == "error"
        else "tool"
    )
    attributes = _safe_attributes(
        item,
        (
            "agent",
            "agent_name",
            "model",
            "requested_model",
            "receiver_thread_id",
            "sender_thread_id",
            "server",
            "thread_id",
            "tool",
        ),
    )
    receiver_thread_ids = item.get("receiver_thread_ids")
    if isinstance(receiver_thread_ids, list):
        attributes["receiver_thread_ids"] = _bounded(
            ",".join(
                thread_id
                for thread_id in receiver_thread_ids
                if isinstance(thread_id, str)
            )
        )
        attributes["receiver_count"] = len(receiver_thread_ids)
    agent_states = item.get("agents_states")
    if isinstance(agent_states, dict):
        attributes["agent_states"] = _bounded(
            ",".join(
                f"{thread_id}:{state.get('status', 'unknown')}"
                for thread_id, state in sorted(agent_states.items())
                if isinstance(thread_id, str) and isinstance(state, dict)
            )
        )
    command = item.get("command")
    if item_type == "command_execution" and isinstance(command, str):
        attributes["command"] = _bounded(normalize_shell_command(command))
    return AgentEvent(
        category=category,
        name=name,
        status=_item_status(item),
        attributes=tuple(attributes.items()),
    )


def _codex_item_name(item_type: str, item: dict[str, Any]) -> str:
    if item_type == "command_execution":
        return "shell"
    if item_type == "file_change":
        return "apply_patch"
    server = item.get("server")
    tool = item.get("tool")
    if isinstance(server, str) and isinstance(tool, str):
        return f"{server}.{tool}"
    if isinstance(tool, str):
        return tool
    name = item.get("name")
    return name if isinstance(name, str) else item_type


def _item_status(item: dict[str, Any]) -> str:
    status = item.get("status")
    if isinstance(status, str):
        return status
    exit_code = item.get("exit_code")
    if isinstance(exit_code, int):
        return "completed" if exit_code == 0 else "failed"
    return "observed"


def _codex_token_usage(usage: dict[str, Any]) -> TokenUsage:
    input_tokens = _integer(usage.get("input_tokens"))
    cached_input_tokens = _integer(usage.get("cached_input_tokens"))
    output_tokens = _integer(usage.get("output_tokens"))
    total_tokens = _integer(usage.get("total_tokens"))
    if total_tokens is None and input_tokens is not None and output_tokens is not None:
        total_tokens = input_tokens + output_tokens
    uncached_input_tokens = None
    if input_tokens is not None and cached_input_tokens is not None:
        uncached_input_tokens = input_tokens - cached_input_tokens
    return TokenUsage(
        source="codex.turn.completed.usage",
        input_tokens=input_tokens,
        uncached_input_tokens=uncached_input_tokens,
        cached_input_tokens=cached_input_tokens,
        cache_creation_input_tokens=_integer(usage.get("cache_write_input_tokens")),
        output_tokens=output_tokens,
        reasoning_output_tokens=_integer(usage.get("reasoning_output_tokens")),
        total_tokens=total_tokens,
    )


def _claude_token_usage(usage: object) -> TokenUsage:
    if not isinstance(usage, dict):
        return TokenUsage(source="claude.result.usage")
    uncached_input_tokens = _integer(usage.get("input_tokens"))
    cached_input_tokens = _integer(usage.get("cache_read_input_tokens"))
    cache_creation_input_tokens = _integer(usage.get("cache_creation_input_tokens"))
    output_tokens = _integer(usage.get("output_tokens"))
    input_dimensions = (
        uncached_input_tokens,
        cached_input_tokens,
        cache_creation_input_tokens,
    )
    input_tokens = (
        sum(value or 0 for value in input_dimensions)
        if any(value is not None for value in input_dimensions)
        else None
    )
    total_tokens = (
        input_tokens + output_tokens
        if input_tokens is not None and output_tokens is not None
        else None
    )
    return TokenUsage(
        source="claude.result.usage",
        input_tokens=input_tokens,
        uncached_input_tokens=uncached_input_tokens,
        cached_input_tokens=cached_input_tokens,
        cache_creation_input_tokens=cache_creation_input_tokens,
        output_tokens=output_tokens,
        reasoning_output_tokens=_integer(usage.get("reasoning_output_tokens")),
        total_tokens=total_tokens,
    )


def _claude_tool_results(events: tuple[dict[str, Any], ...]) -> dict[str, str]:
    results: dict[str, str] = {}
    for event in events:
        if event.get("type") != "user":
            continue
        for content in event.get("message", {}).get("content", []):
            if content.get("type") != "tool_result":
                continue
            tool_use_id = content.get("tool_use_id")
            if isinstance(tool_use_id, str):
                results[tool_use_id] = (
                    "failed" if content.get("is_error") else "completed"
                )
    return results


def _claude_tool_event(
    content: dict[str, Any],
    tool_results: dict[str, str],
) -> AgentEvent:
    tool_name = content.get("name")
    name = tool_name if isinstance(tool_name, str) else "unknown"
    category: AgentEventCategory = (
        "agent" if "agent" in name.lower() or name == "Task" else "tool"
    )
    tool_input = content.get("input")
    attributes = (
        _safe_attributes(
            tool_input,
            ("agent", "description", "model", "name", "subagent_type"),
        )
        if isinstance(tool_input, dict)
        else {}
    )
    if name == "Bash" and isinstance(tool_input, dict):
        command = tool_input.get("command")
        if isinstance(command, str):
            attributes["command"] = _bounded(normalize_shell_command(command))
    tool_use_id = content.get("id")
    status = (
        tool_results.get(tool_use_id, "observed")
        if isinstance(tool_use_id, str)
        else "observed"
    )
    return AgentEvent(
        category=category,
        name=name,
        status=status,
        attributes=tuple(attributes.items()),
    )


def _model_ids_from_events(events: tuple[dict[str, Any], ...]) -> tuple[str, ...]:
    model_ids = {
        model_id
        for event in events
        if isinstance((model_id := event.get("model")), str)
    }
    return tuple(sorted(model_ids))


def _claude_model_ids(
    events: tuple[dict[str, Any], ...],
    result_event: dict[str, Any],
) -> tuple[str, ...]:
    model_ids = {
        model_id
        for event in events
        if event.get("type") == "assistant"
        and isinstance((model_id := event.get("message", {}).get("model")), str)
    }
    model_usage = result_event.get("modelUsage")
    if isinstance(model_usage, dict):
        model_ids.update(
            model_id for model_id in model_usage if isinstance(model_id, str)
        )
    return tuple(sorted(model_ids))


def _safe_attributes(
    source: dict[str, Any],
    allowed_names: tuple[str, ...],
) -> dict[str, EvidenceValue]:
    attributes: dict[str, EvidenceValue] = {}
    for name in allowed_names:
        value = source.get(name)
        if isinstance(value, (str, int, float, bool)):
            attributes[name] = _bounded(value) if isinstance(value, str) else value
    return attributes


def _bounded(value: str, limit: int = 1000) -> str:
    """Bound free-form trace attributes while preserving scorer evidence elsewhere."""
    return value if len(value) <= limit else f"{value[:limit]}…"


def _integer(value: object) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) else None
