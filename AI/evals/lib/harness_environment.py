"""Stable repository and agent-profile constants shared by the eval harness."""

from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
SUPPORTED_AGENT_PROFILES = ("codex", "claude")
AGENT_ARGUMENT_CHOICES = ("auto", *SUPPORTED_AGENT_PROFILES)
