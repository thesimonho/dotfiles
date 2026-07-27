"""Shared parsing for normalized shell-command evidence."""

import os
import shlex


def shell_segments(command: str) -> tuple[tuple[str, ...], ...]:
    """Split a shell string into simple command segments."""
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars="|&;")
        lexer.whitespace_split = True
        tokens = tuple(lexer)
    except ValueError:
        tokens = tuple(command.split())
    segments: list[tuple[str, ...]] = []
    current_segment: list[str] = []
    for token in tokens:
        if token and all(character in "|&;" for character in token):
            if current_segment:
                segments.append(tuple(current_segment))
                current_segment = []
            continue
        current_segment.append(token)
    if current_segment:
        segments.append(tuple(current_segment))
    return tuple(segments)


def executable_index(segment: tuple[str, ...]) -> int | None:
    """Return the executable position after leading environment assignments."""
    return next(
        (
            index
            for index, token in enumerate(segment)
            if not ("=" in token and not token.startswith(("=", "-")))
        ),
        None,
    )


def unwrapped_shell_invocations(command: str) -> tuple[tuple[str, ...], ...]:
    """Return executable-led invocations, including commands inside wrappers."""
    invocations: list[tuple[str, ...]] = []
    for segment in shell_segments(command):
        index = executable_index(segment)
        if index is None:
            continue
        invocation = segment[index:]
        if os.path.basename(invocation[0]) == "rtk":
            invocation = invocation[1:]
        if not invocation:
            continue
        invocations.append(invocation)
        invocations.extend(_wrapped_shell_invocations(invocation))
    return tuple(invocations)


def _wrapped_shell_invocations(
    invocation: tuple[str, ...],
) -> tuple[tuple[str, ...], ...]:
    """Parse a command string delegated through a common shell wrapper."""
    if os.path.basename(invocation[0]) not in {"bash", "sh", "zsh"}:
        return ()
    for flag in ("-c", "-lc"):
        if flag not in invocation[1:]:
            continue
        command_index = invocation.index(flag) + 1
        if command_index < len(invocation):
            return unwrapped_shell_invocations(invocation[command_index])
    return ()
