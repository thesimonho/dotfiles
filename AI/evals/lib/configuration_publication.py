"""MLflow publication result for one complete agent configuration."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from configuration_manifest import ConfigurationChanges, ConfigurationManifest


@dataclass(frozen=True)
class ConfigurationPublication:
    """Published component and manifest versions ready to associate with a run."""

    manifest: ConfigurationManifest
    manifest_prompt: Any
    changes: ConfigurationChanges
    baseline_prompt_version: int | None

    @property
    def run_metadata(self) -> dict[str, str]:
        """Return compact string metadata for MLflow runs and traces."""
        baseline_manifest_id = (
            self.changes.baseline.manifest_id if self.changes.baseline else "none"
        )
        return {
            "config_manifest_id": self.manifest.manifest_id,
            "config_manifest_prompt": _prompt_reference(self.manifest_prompt),
            "config_baseline_manifest_id": baseline_manifest_id,
            "config_baseline_prompt_version": str(
                self.baseline_prompt_version or "none"
            ),
            "config_changes": self.changes.summary,
        }


def _prompt_reference(prompt: Any) -> str:
    uri = getattr(prompt, "uri", None)
    if not uri:
        raise ValueError("MLflow prompt version did not provide a URI")
    return str(uri)
