"""Resolved child-session evidence from an isolated Codex profile."""

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class ResolvedCodexSubagent:
    """Actual child configuration recorded by Codex after precedence resolution."""

    thread_id: str
    role: str | None
    nickname: str | None
    model: str
    effort: str


def resolved_codex_subagents(
    codex_home: Path,
    parent_thread_id: str | None,
) -> tuple[ResolvedCodexSubagent, ...]:
    """Load direct children of one evaluated parent from Codex rollout JSONL."""
    if parent_thread_id is None:
        return ()
    sessions_root = codex_home / "sessions"
    if not sessions_root.is_dir():
        return ()
    children = []
    for rollout_path in sessions_root.rglob("*.jsonl"):
        child = _resolved_child(rollout_path, parent_thread_id)
        if child is not None:
            children.append(child)
    return tuple(sorted(children, key=lambda child: child.thread_id))


def parent_thread_id(events: tuple[dict[str, Any], ...]) -> str | None:
    """Return the evaluated parent thread ID from its JSON event stream."""
    return next(
        (
            str(event["thread_id"])
            for event in events
            if event.get("type") == "thread.started"
            and isinstance(event.get("thread_id"), str)
        ),
        None,
    )


def _resolved_child(
    rollout_path: Path,
    expected_parent_thread_id: str,
) -> ResolvedCodexSubagent | None:
    session_meta = None
    turn_context = None
    for line in rollout_path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        event = json.loads(line)
        if event.get("type") == "session_meta" and session_meta is None:
            session_meta = event.get("payload")
        elif event.get("type") == "turn_context" and turn_context is None:
            turn_context = event.get("payload")
        if session_meta is not None and turn_context is not None:
            break
    if not isinstance(session_meta, dict) or not isinstance(turn_context, dict):
        return None
    if session_meta.get("parent_thread_id") != expected_parent_thread_id:
        return None
    thread_id = session_meta.get("id")
    model = turn_context.get("model")
    effort = turn_context.get("effort")
    if not all(isinstance(value, str) for value in (thread_id, model, effort)):
        return None
    role = session_meta.get("agent_role")
    nickname = session_meta.get("agent_nickname")
    return ResolvedCodexSubagent(
        thread_id=thread_id,
        role=role if isinstance(role, str) else None,
        nickname=nickname if isinstance(nickname, str) else None,
        model=model,
        effort=effort,
    )
