"""Load the git-tracked master catalog of instruction hypotheses."""

import tomllib
from pathlib import Path

from evaluation_coverage import InstructionCoverage

CATALOG_PATH = Path(__file__).resolve().parent / "catalog.toml"


def _load_instruction_coverage() -> tuple[InstructionCoverage, ...]:
    """Parse catalog.toml instruction entries in stable component order."""
    catalog = tomllib.loads(CATALOG_PATH.read_text())
    entries = catalog.get("instruction", {})
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
