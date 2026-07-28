"""Plan-event recognition independent of normalized event rendering."""

from typing import Any


def codex_has_plan(events: tuple[dict[str, Any], ...]) -> bool:
    """Recognize a Codex plan update even without a completed item."""
    return any(
        event.get("type") in {"item.updated", "item.completed"}
        and isinstance(event.get("item"), dict)
        and event["item"].get("type") == "todo_list"
        for event in events
    )
