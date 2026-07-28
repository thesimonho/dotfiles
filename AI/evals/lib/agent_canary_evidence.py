"""Exact custom-agent definition canary recognition."""


def has_exact_canary_footer(message: str, expected_canary: str) -> bool:
    """Require the opaque marker as the final unformatted response line."""
    lines = tuple(line.strip() for line in message.splitlines() if line.strip())
    return bool(lines) and lines[-1] == expected_canary
