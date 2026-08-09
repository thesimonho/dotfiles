"""Order-sensitive metric scoring over normalized agent event streams."""

from typing import Any


def event_command(event: dict[str, Any]) -> str:
    """Render an event's command-like attributes for marker matching."""
    attributes = event.get("attributes")
    if not isinstance(attributes, dict):
        return ""
    return " ".join(
        str(attributes.get(field, "")) for field in ("command", "file_path")
    ).strip()


def is_effective_file_change(event: dict[str, Any]) -> bool:
    """Whether an event actually altered a file.

    Failed file-change events altered nothing: hook-blocked edits (for
    example branch-guard on the default branch) and rejected edits must not
    count as changes in any event-ordering metric.
    """
    return (
        event.get("evidence_type") == "tool.file-change"
        and event.get("status") != "failed"
    )


def is_documentation_change(event: dict[str, Any]) -> bool:
    """Whether a file change only touched documentation."""
    attributes = event.get("attributes")
    path = str(attributes.get("file_path", "")) if isinstance(attributes, dict) else ""
    if not path:
        return False
    return path.endswith((".md", ".mdx", ".txt")) or path.startswith("docs/")


def score_final_verify(events: tuple[dict[str, Any], ...]) -> tuple[float, str]:
    """Require the verify skill to run after the last substantive change.

    Verification gates a merge or pull request, not every individual commit,
    and re-running it after an inconsequential edit proves nothing. A
    documentation-only change following a completed verification therefore
    leaves the run compliant, and a run that changed no code never needed
    verification at all.
    """
    substantive_indexes = [
        index
        for index, event in enumerate(events)
        if is_effective_file_change(event) and not is_documentation_change(event)
    ]
    verify_indexes = [
        index
        for index, event in enumerate(events)
        if (
            event.get("evidence_type") == "agent.skill"
            and "verify" in str(event.get("attributes", {})).lower()
        )
        or "AI/skills/verify/SKILL.md" in event_command(event)
    ]
    if not substantive_indexes:
        return 100.0, "no code changes required verification"
    if not verify_indexes:
        return 0.0, "code changed but the verify skill was never invoked"
    passed = verify_indexes[-1] > substantive_indexes[-1]
    return (100.0 if passed else 0.0), (
        "verify skill ran after the last substantive change"
        if passed
        else "verify skill ran before a later substantive change"
    )


def score_tdd_sequence(
    events: tuple[dict[str, Any], ...], patterns: tuple[str, ...], policy: str
) -> tuple[float, str]:
    """Check failing-test-first then passing-test-after around real changes."""
    test_events = [
        (index, str(event.get("status", "")))
        for index, event in enumerate(events)
        if any(pattern in event_command(event) for pattern in patterns)
    ]
    change_indexes = [
        index for index, event in enumerate(events) if is_effective_file_change(event)
    ]
    has_failing_test_first = bool(
        test_events
        and change_indexes
        and test_events[0][0] < change_indexes[0]
        and test_events[0][1] == "failed"
    )
    has_test_after = bool(
        test_events
        and change_indexes
        and test_events[-1][0] > change_indexes[-1]
        and test_events[-1][1] == "completed"
    )
    invoked_tdd_skill = any(
        "tdd/SKILL.md" in event_command(event)
        or (
            event.get("evidence_type") == "agent.skill"
            and "tdd" in str(event.get("attributes", {})).lower()
        )
        for event in events
    )
    passed = (
        (has_failing_test_first and has_test_after)
        if policy == "expected"
        else not invoked_tdd_skill
    )
    return (100.0 if passed else 0.0), (
        f"TDD policy {policy}; failing-test-first={has_failing_test_first}; "
        f"test-after={has_test_after}; skill-invoked={invoked_tdd_skill}"
    )


def score_branch_before_changes(
    events: tuple[dict[str, Any], ...],
) -> tuple[float, str]:
    """Require a task branch before the first effective file change."""
    branch_index = next(
        (
            index
            for index, event in enumerate(events)
            if any(
                marker in event_command(event)
                for marker in (
                    "git switch -c",
                    "git checkout -b",
                    "git worktree add -b",
                )
            )
        ),
        None,
    )
    change_index = next(
        (
            index
            for index, event in enumerate(events)
            if is_effective_file_change(event)
        ),
        None,
    )
    passed = branch_index is not None and (
        change_index is None or branch_index < change_index
    )
    return (100.0 if passed else 0.0), (
        "task branch preceded file changes"
        if passed
        else "task branch did not precede file changes"
    )


def score_worktree_lifecycle(
    events: tuple[dict[str, Any], ...],
) -> tuple[float, str]:
    """Score worktree create, effective change inside it, and removal."""
    create_index = next(
        (
            index
            for index, event in enumerate(events)
            if "git worktree add" in event_command(event)
        ),
        None,
    )
    remove_index = next(
        (
            index
            for index, event in enumerate(events)
            if "git worktree remove" in event_command(event)
        ),
        None,
    )
    changed_inside_worktree = (
        create_index is not None
        and remove_index is not None
        and any(
            create_index < index < remove_index and is_effective_file_change(event)
            for index, event in enumerate(events)
        )
    )
    stages = (
        create_index is not None,
        changed_inside_worktree,
        remove_index is not None,
    )
    return sum(
        stages
    ) / 3 * 100, f"completed {sum(stages)} of 3 worktree lifecycle stages"
