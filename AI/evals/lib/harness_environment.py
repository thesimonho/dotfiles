"""Stable repository and agent-profile constants shared by the eval harness."""

import tomllib
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
EVALUATION_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = EVALUATION_ROOT / "catalog.toml"
SUPPORTED_AGENT_PROFILES = ("codex", "claude")
AGENT_ARGUMENT_CHOICES = ("auto", *SUPPORTED_AGENT_PROFILES)


def resolve_evaluation_compute(
    profile: str,
    model: str | None,
    effort: str | None,
) -> tuple[str, str]:
    """Apply catalog defaults while preserving independent explicit overrides."""
    if profile not in SUPPORTED_AGENT_PROFILES:
        raise ValueError(f"unsupported evaluation profile: {profile}")
    catalog = tomllib.loads(CATALOG_PATH.read_text())
    defaults = catalog.get("defaults", {}).get(profile)
    if (
        not isinstance(defaults, dict)
        or not isinstance(defaults.get("model"), str)
        or not isinstance(defaults.get("effort"), str)
    ):
        raise ValueError(
            f"catalog.toml must define [defaults.{profile}] model and effort"
        )
    return model or defaults["model"], effort or defaults["effort"]
