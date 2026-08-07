"""Exact custom-agent definition canary recognition."""

from typing import Any


def has_exact_canary_footer(message: str, expected_canary: str) -> bool:
    """Require the opaque marker as the final unformatted response line."""
    lines = tuple(line.strip() for line in message.splitlines() if line.strip())
    return bool(lines) and lines[-1] == expected_canary


def claude_canary_tool_use_ids(
    events: tuple[dict[str, Any], ...],
    expected_canary: str | None,
) -> tuple[str, ...]:
    """Return Agent or Task tool-use IDs whose results end with the canary."""
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
        tool_use_id
        for event in events
        if event.get("type") == "user"
        for content in event.get("message", {}).get("content", [])
        if content.get("type") == "tool_result"
        and isinstance((tool_use_id := content.get("tool_use_id")), str)
        and tool_use_id in agent_tool_ids
        and has_exact_canary_footer(
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
