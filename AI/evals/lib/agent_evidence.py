"""Normalize inspectable execution evidence from agent CLI event streams."""

from __future__ import annotations

import os
import shlex
from dataclasses import asdict, dataclass
from typing import Any, Literal

from agent_event_contract import AgentEventCoverage

type EvidenceValue = str | int | float | bool
type AgentEventCategory = Literal["agent", "runtime", "tool"]

_KNOWN_CODEX_COLLABORATION_TOOLS = {
    "close_agent",
    "send_input",
    "spawn_agent",
    "wait",
}
_KNOWN_CLAUDE_TOOLS = {
    "Agent",
    "AskUserQuestion",
    "Bash",
    "Edit",
    "EnterPlanMode",
    "ExitPlanMode",
    "Glob",
    "Grep",
    "KillShell",
    "LSP",
    "MultiEdit",
    "NotebookEdit",
    "Read",
    "Skill",
    "Task",
    "TaskCreate",
    "TaskGet",
    "TaskList",
    "TaskOutput",
    "TaskStop",
    "TaskUpdate",
    "TodoWrite",
    "ToolSearch",
    "WebFetch",
    "WebSearch",
    "Write",
}


@dataclass(frozen=True)
class AgentEvent:
    """One safe, normalized observation from an agent CLI event stream."""

    category: AgentEventCategory
    name: str
    evidence_type: str
    status: str
    attributes: tuple[tuple[str, EvidenceValue], ...] = ()

    def to_dict(self) -> dict[str, object]:
        """Render the event without exposing an arbitrary raw CLI payload."""
        return {
            "category": self.category,
            "name": self.name,
            "evidence_type": self.evidence_type,
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
    agent_definition_canary: str | None = None,
) -> tuple[
    tuple[AgentEvent, ...],
    TokenUsage,
    tuple[str, ...],
    AgentEventCoverage,
]:
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
    agent_events = (
        *agent_events,
        *_codex_definition_canary_events(
            completed_items,
            agent_definition_canary,
        ),
        *_codex_runtime_events(events),
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
    coverage = _codex_event_coverage(events, agent_events, token_usage)
    return agent_events, token_usage, model_ids, coverage


def claude_evidence(
    events: tuple[dict[str, Any], ...],
    result_event: dict[str, Any],
    agent_definition_canary: str | None = None,
) -> tuple[
    tuple[AgentEvent, ...],
    TokenUsage,
    tuple[str, ...],
    AgentEventCoverage,
]:
    """Normalize Claude tool-use blocks, result usage, and emitted model IDs."""
    tool_results = _claude_tool_results(events)
    agent_events = (
        *tuple(
            _claude_tool_event(content, tool_results)
            for event in events
            if event.get("type") == "assistant"
            for content in event.get("message", {}).get("content", [])
            if content.get("type") == "tool_use"
        ),
        *_claude_definition_canary_events(events, agent_definition_canary),
    )
    token_usage = _claude_token_usage(result_event.get("usage", {}))
    model_ids = _claude_model_ids(events, result_event)
    coverage = _claude_event_coverage(events, agent_events, token_usage)
    return agent_events, token_usage, model_ids, coverage


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
        evidence_type=_codex_item_evidence_type(item_type, item),
        status=_item_status(item),
        attributes=tuple(attributes.items()),
    )


def _codex_item_name(item_type: str, item: dict[str, Any]) -> str:
    if item_type == "command_execution":
        return "shell"
    if item_type == "file_change":
        return "apply_patch"
    if item_type == "collab_tool_call":
        collaboration_names = {
            "close_agent": "close",
            "send_input": "send",
            "spawn_agent": "spawn",
            "wait": "wait",
        }
        tool = item.get("tool")
        if isinstance(tool, str):
            return collaboration_names.get(tool, tool)
    server = item.get("server")
    tool = item.get("tool")
    if isinstance(server, str) and isinstance(tool, str):
        return f"{server}.{tool}"
    if isinstance(tool, str):
        return tool
    name = item.get("name")
    return name if isinstance(name, str) else item_type


def _codex_item_evidence_type(item_type: str, item: dict[str, Any]) -> str:
    if item_type == "collab_tool_call":
        return (
            "agent.spawn"
            if item.get("tool") == "spawn_agent"
            else "agent.collaboration"
        )
    evidence_types = {
        "command_execution": "tool.shell",
        "error": "runtime.error",
        "file_change": "tool.file-change",
        "mcp_tool_call": "tool.mcp",
        "web_search": "tool.web-search",
    }
    return evidence_types.get(item_type, "tool.other")


def _codex_runtime_events(
    events: tuple[dict[str, Any], ...],
) -> tuple[AgentEvent, ...]:
    runtime_events = []
    for event in events:
        event_type = event.get("type")
        if event_type == "error":
            message = event.get("message")
        elif event_type == "turn.failed":
            error = event.get("error")
            message = error.get("message") if isinstance(error, dict) else None
        else:
            continue
        attributes = (
            (("message", _bounded(message)),) if isinstance(message, str) else ()
        )
        runtime_events.append(
            AgentEvent(
                category="runtime",
                name="error",
                evidence_type="runtime.error",
                status="failed",
                attributes=attributes,
            )
        )
    return tuple(runtime_events)


def _codex_definition_canary_events(
    completed_items: tuple[dict[str, Any], ...],
    expected_canary: str | None,
) -> tuple[AgentEvent, ...]:
    """Expose only an expected marker from completed child-agent messages."""
    if expected_canary is None:
        return ()
    canary_events = []
    observed_thread_ids = set()
    for item in completed_items:
        agent_states = item.get("agents_states")
        if not isinstance(agent_states, dict):
            continue
        for thread_id, state in sorted(agent_states.items()):
            if (
                not isinstance(thread_id, str)
                or thread_id in observed_thread_ids
                or not isinstance(state, dict)
            ):
                continue
            message = state.get("message")
            if not isinstance(message, str) or not _has_exact_canary_footer(
                message,
                expected_canary,
            ):
                continue
            observed_thread_ids.add(thread_id)
            canary_events.append(
                AgentEvent(
                    category="agent",
                    name="definition-canary",
                    evidence_type="agent.definition-canary",
                    status="completed",
                    attributes=(("thread_id", _bounded(thread_id, 100)),),
                )
            )
    return tuple(canary_events)


def _claude_definition_canary_events(
    events: tuple[dict[str, Any], ...],
    expected_canary: str | None,
) -> tuple[AgentEvent, ...]:
    """Recognize an exact canary footer only in Agent or Task results."""
    if expected_canary is None:
        return ()
    agent_tool_ids = {
        content["id"]
        for event in events
        if event.get("type") == "assistant"
        for content in event.get("message", {}).get("content", [])
        if content.get("type") == "tool_use"
        and content.get("name") in {"Agent", "Task"}
        and isinstance(content.get("id"), str)
    }
    return tuple(
        AgentEvent(
            category="agent",
            name="definition-canary",
            evidence_type="agent.definition-canary",
            status="completed",
            attributes=(("tool_use_id", _bounded(tool_use_id, 100)),),
        )
        for event in events
        if event.get("type") == "user"
        for content in event.get("message", {}).get("content", [])
        if content.get("type") == "tool_result"
        and isinstance((tool_use_id := content.get("tool_use_id")), str)
        and tool_use_id in agent_tool_ids
        and _has_exact_canary_footer(
            _claude_tool_result_text(content),
            expected_canary,
        )
    )


def _claude_tool_result_text(content: dict[str, Any]) -> str:
    """Flatten only textual Claude tool-result content for exact matching."""
    result_content = content.get("content")
    if isinstance(result_content, str):
        return result_content
    if not isinstance(result_content, list):
        return ""
    return "\n".join(
        block["text"]
        for block in result_content
        if isinstance(block, dict) and isinstance(block.get("text"), str)
    )


def _has_exact_canary_footer(message: str, expected_canary: str) -> bool:
    """Require the opaque marker as the final unformatted response line."""
    lines = tuple(line.strip() for line in message.splitlines() if line.strip())
    return bool(lines) and lines[-1] == expected_canary


def _codex_event_coverage(
    events: tuple[dict[str, Any], ...],
    agent_events: tuple[AgentEvent, ...],
    token_usage: TokenUsage,
) -> AgentEventCoverage:
    known_top_level_types = {
        "error",
        "item.completed",
        "item.started",
        "item.updated",
        "thread.started",
        "turn.completed",
        "turn.failed",
        "turn.started",
    }
    known_item_types = {
        "agent_message",
        "collab_tool_call",
        "command_execution",
        "error",
        "file_change",
        "mcp_tool_call",
        "reasoning",
        "todo_list",
        "web_search",
    }
    event_keys = tuple(_codex_event_key(event) for event in events)
    unknown_event_types = {
        event_key
        for event, event_key in zip(events, event_keys, strict=True)
        if event.get("type") not in known_top_level_types
        or (
            str(event.get("type", "")).startswith("item.")
            and _codex_item_type(event) not in known_item_types
        )
        or _codex_collaboration_tool_is_unknown(event)
    }
    intentionally_ignored = {
        event_key
        for event, event_key in zip(events, event_keys, strict=True)
        if event.get("type") in {"thread.started", "turn.started"}
        or (
            event.get("type") in {"item.started", "item.updated"}
            and _codex_item_type(event) in known_item_types
            and not _codex_collaboration_tool_is_unknown(event)
        )
        or (
            event.get("type") == "item.completed"
            and _codex_item_type(event) in {"reasoning", "todo_list"}
        )
    }
    normalized_evidence_types = {event.evidence_type for event in agent_events}
    if any(event_key == "item.completed.agent_message" for event_key in event_keys):
        normalized_evidence_types.add("agent.message")
    if token_usage.available_counts():
        normalized_evidence_types.add("token.usage")
    return AgentEventCoverage(
        observed_event_types=tuple(sorted(set(event_keys))),
        normalized_evidence_types=tuple(sorted(normalized_evidence_types)),
        intentionally_ignored_event_types=tuple(sorted(intentionally_ignored)),
        unknown_event_types=tuple(sorted(unknown_event_types)),
    )


def _codex_event_key(event: dict[str, Any]) -> str:
    event_type = event.get("type")
    if not isinstance(event_type, str):
        return "<missing-type>"
    item_type = _codex_item_type(event)
    if item_type is None:
        return event_type
    item = event.get("item")
    tool = item.get("tool") if isinstance(item, dict) else None
    if item_type == "collab_tool_call" and isinstance(tool, str):
        return f"{event_type}.{item_type}.{_bounded(tool, 100)}"
    return f"{event_type}.{item_type}"


def _codex_item_type(event: dict[str, Any]) -> str | None:
    item = event.get("item")
    item_type = item.get("type") if isinstance(item, dict) else None
    return item_type if isinstance(item_type, str) else None


def _codex_collaboration_tool_is_unknown(event: dict[str, Any]) -> bool:
    """Detect new collaboration operations without treating their payload as evidence."""
    if _codex_item_type(event) != "collab_tool_call":
        return False
    item = event.get("item")
    tool = item.get("tool") if isinstance(item, dict) else None
    return tool not in _KNOWN_CODEX_COLLABORATION_TOOLS


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
    source_name = tool_name if isinstance(tool_name, str) else "unknown"
    name = "spawn" if source_name in {"Agent", "Task"} else source_name
    category: AgentEventCategory = (
        "agent" if "agent" in source_name.lower() or name == "spawn" else "tool"
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
    if source_name == "Bash" and isinstance(tool_input, dict):
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
        evidence_type=_claude_tool_evidence_type(source_name),
        status=status,
        attributes=tuple(attributes.items()),
    )


def _claude_tool_evidence_type(name: str) -> str:
    if name == "Bash":
        return "tool.shell"
    if name in {"Agent", "Task"} or "agent" in name.lower():
        return "agent.spawn"
    if name in {"Edit", "MultiEdit", "NotebookEdit", "Write"}:
        return "tool.file-change"
    if name in {"WebFetch", "WebSearch"}:
        return "tool.web-search"
    if name.startswith("mcp__"):
        return "tool.mcp"
    return "tool.other"


def _claude_event_coverage(
    events: tuple[dict[str, Any], ...],
    agent_events: tuple[AgentEvent, ...],
    token_usage: TokenUsage,
) -> AgentEventCoverage:
    known_top_level_types = {
        "assistant",
        "rate_limit_event",
        "result",
        "stream_event",
        "system",
        "user",
    }
    known_content_types = {
        "redacted_thinking",
        "text",
        "thinking",
        "tool_result",
        "tool_use",
    }
    event_keys = tuple(
        event_key for event in events for event_key in _claude_event_keys(event)
    )
    unknown_event_types = {
        event_key
        for event_key in event_keys
        if _claude_event_key_is_unknown(
            event_key,
            known_top_level_types,
            known_content_types,
            _KNOWN_CLAUDE_TOOLS,
        )
    }
    intentionally_ignored = {
        event_key
        for event_key in event_keys
        if event_key in {"rate_limit_event", "stream_event", "system"}
        or event_key.rsplit(".", maxsplit=1)[-1]
        in {"redacted_thinking", "text", "thinking"}
    }
    normalized_evidence_types = {event.evidence_type for event in agent_events}
    if any(event.get("type") == "result" for event in events):
        normalized_evidence_types.add("agent.message")
    if token_usage.available_counts():
        normalized_evidence_types.add("token.usage")
    if any(
        event.evidence_type == "agent.spawn" and "model" in dict(event.attributes)
        for event in agent_events
    ):
        normalized_evidence_types.add("agent.model-selection")
    return AgentEventCoverage(
        observed_event_types=tuple(sorted(set(event_keys))),
        normalized_evidence_types=tuple(sorted(normalized_evidence_types)),
        intentionally_ignored_event_types=tuple(sorted(intentionally_ignored)),
        unknown_event_types=tuple(sorted(unknown_event_types)),
    )


def _claude_event_keys(event: dict[str, Any]) -> tuple[str, ...]:
    event_type = event.get("type")
    if not isinstance(event_type, str):
        return ("<missing-type>",)
    message = event.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    if not isinstance(content, list):
        return (event_type,)
    content_keys = tuple(
        _claude_content_key(event_type, content_block)
        for content_block in content
        if isinstance(content_block, dict)
        and isinstance(content_block.get("type"), str)
    )
    return (event_type, *content_keys)


def _claude_content_key(event_type: str, content: dict[str, Any]) -> str:
    """Include bounded tool discriminators so new tool shapes cannot pass silently."""
    content_type = content["type"]
    if content_type != "tool_use":
        return f"{event_type}.content.{content_type}"
    tool_name = content.get("name")
    if not isinstance(tool_name, str):
        return f"{event_type}.content.tool_use.<missing-name>"
    discriminator = "mcp" if tool_name.startswith("mcp__") else _bounded(tool_name, 100)
    return f"{event_type}.content.tool_use.{discriminator}"


def _claude_event_key_is_unknown(
    event_key: str,
    known_top_level_types: set[str],
    known_content_types: set[str],
    known_tool_names: set[str],
) -> bool:
    if ".content." not in event_key:
        return event_key not in known_top_level_types
    _, content_type = event_key.rsplit(".content.", maxsplit=1)
    if content_type.startswith("tool_use."):
        tool_name = content_type.removeprefix("tool_use.")
        return tool_name != "mcp" and tool_name not in known_tool_names
    return content_type not in known_content_types


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
