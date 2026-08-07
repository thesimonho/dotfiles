"""Single owner of the git-tracked catalog.toml master configuration."""

import tomllib
from functools import cache
from typing import Any

from evaluation_coverage import InstructionCoverage
from harness_environment import EVALUATION_ROOT, SUPPORTED_AGENT_PROFILES

CATALOG_PATH = EVALUATION_ROOT / "catalog.toml"


@cache
def _load_catalog() -> dict[str, Any]:
    return tomllib.loads(CATALOG_PATH.read_text())


def resolve_evaluation_compute(
    profile: str,
    model: str | None,
    effort: str | None,
) -> tuple[str, str]:
    """Apply catalog defaults while preserving independent explicit overrides."""
    if profile not in SUPPORTED_AGENT_PROFILES:
        raise ValueError(f"unsupported evaluation profile: {profile}")
    defaults = _load_catalog().get("defaults", {}).get(profile)
    if (
        not isinstance(defaults, dict)
        or not isinstance(defaults.get("model"), str)
        or not isinstance(defaults.get("effort"), str)
    ):
        raise ValueError(
            f"catalog.toml must define [defaults.{profile}] model and effort"
        )
    return model or defaults["model"], effort or defaults["effort"]


def _load_instruction_coverage() -> tuple[InstructionCoverage, ...]:
    """Parse catalog.toml instruction entries in stable component order."""
    entries = _load_catalog().get("instruction", {})
    return tuple(
        InstructionCoverage(
            component_id=f"instruction/{name}",
            hypothesis=entry["hypothesis"],
            maturity=entry["maturity"],
            case_ids=tuple(entry.get("cases", ())),
            enabled=entry.get("enabled", True),
        )
        for name, entry in sorted(entries.items())
    )


INSTRUCTION_COVERAGE = _load_instruction_coverage()
