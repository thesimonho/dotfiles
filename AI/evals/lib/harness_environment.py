"""Stable repository and agent-profile constants shared by the eval harness."""

from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
EVALUATION_ROOT = Path(__file__).resolve().parents[1]
SUPPORTED_AGENT_PROFILES = ("codex", "claude")
AGENT_ARGUMENT_CHOICES = ("auto", *SUPPORTED_AGENT_PROFILES)
DEFAULT_CODEX_MODEL = "gpt-5.6-sol"
DEFAULT_CODEX_EFFORT = "low"
DEFAULT_CLAUDE_MODEL = "opus"
DEFAULT_CLAUDE_EFFORT = "medium"


def resolve_evaluation_compute(
    profile: str,
    model: str | None,
    effort: str | None,
) -> tuple[str, str]:
    """Apply profile defaults while preserving independent explicit overrides."""
    default_compute = {
        "codex": (DEFAULT_CODEX_MODEL, DEFAULT_CODEX_EFFORT),
        "claude": (DEFAULT_CLAUDE_MODEL, DEFAULT_CLAUDE_EFFORT),
    }
    if profile not in default_compute:
        raise ValueError(f"unsupported evaluation profile: {profile}")
    default_model, default_effort = default_compute[profile]
    return model or default_model, effort or default_effort
