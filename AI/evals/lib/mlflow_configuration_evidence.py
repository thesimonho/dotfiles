"""Shared configuration evidence rendered on MLflow runs and Agent Versions."""

import json
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

from configuration_publication import ConfigurationPublication

CHANGES_ARTIFACT_PATH = "configuration/changes.txt"
DESCRIPTION_TAG = "mlflow.note.content"
MANIFEST_ARTIFACT_PATH = "configuration/manifest.json"


def configuration_description(publication: ConfigurationPublication) -> str:
    """Describe the manifest, baseline-relative changes, and active components."""
    prompt_lines = "\n".join(
        f"- `{component.component_id}`: `{component.prompt_reference}`"
        for component in publication.manifest.components
    )
    return (
        "## Evaluated configuration\n\n"
        f"Manifest: `{publication.run_metadata['config_manifest_prompt']}`\n\n"
        "### Changes from baseline\n\n"
        f"```text\n{publication.changes.summary}\n```\n\n"
        "### Active configuration components\n\n"
        f"{prompt_lines}"
    )


def agent_version_description(publication: ConfigurationPublication) -> str:
    """Describe only immutable evidence belonging to one manifest identity."""
    prompt_lines = "\n".join(
        f"- `{component.component_id}`: `{component.prompt_reference}`"
        for component in publication.manifest.components
    )
    return (
        "## Agent configuration\n\n"
        f"Manifest: `{publication.run_metadata['config_manifest_prompt']}`\n\n"
        "### Active configuration components\n\n"
        f"{prompt_lines}"
    )


def upload_model_manifest_artifact(
    client: Any,
    model_id: str,
    publication: ConfigurationPublication,
) -> None:
    """Upload the immutable manifest evidence to an Agent Version."""
    with TemporaryDirectory(prefix="mlflow-config-evidence-") as temporary_root:
        artifact_root = Path(temporary_root)
        manifest_path = artifact_root / MANIFEST_ARTIFACT_PATH
        manifest_path.parent.mkdir(parents=True)
        manifest_path.write_text(
            json.dumps(publication.manifest.to_dict(), indent=2, default=str),
            encoding="utf-8",
        )
        client.log_model_artifacts(model_id, temporary_root)
