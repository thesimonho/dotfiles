"""Build and compare complete configuration-set manifests."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass


@dataclass(frozen=True)
class RegisteredComponent:
    """A configuration component resolved to one provider prompt version."""

    component_id: str
    content_hash: str
    prompt_name: str
    prompt_version: int
    prompt_reference: str
    source_paths: tuple[str, ...]


@dataclass(frozen=True)
class ConfigurationManifest:
    """The complete active component set for one evaluated agent config."""

    profile: str
    manifest_id: str
    components: tuple[RegisteredComponent, ...]
    content: str

    def to_dict(self) -> dict:
        """Return the provider-navigable manifest payload."""
        return json.loads(self.content)


@dataclass(frozen=True)
class ConfigurationChanges:
    """Set-based changes between two complete manifests."""

    baseline: ConfigurationManifest | None
    current: ConfigurationManifest
    added: tuple[str, ...]
    removed: tuple[str, ...]
    modified: tuple[str, ...]
    unchanged: tuple[str, ...]
    summary: str


def build_manifest(
    profile: str,
    components: list[RegisteredComponent] | tuple[RegisteredComponent, ...],
) -> ConfigurationManifest:
    """Build a canonical manifest whose identity is provider-independent."""
    ordered_components = tuple(
        sorted(components, key=lambda component: component.component_id)
    )
    identity_payload = {
        "profile": profile,
        "schema_version": 1,
        "components": {
            component.component_id: {
                "content_hash": component.content_hash,
                "source_paths": list(component.source_paths),
            }
            for component in ordered_components
        },
    }
    identity_json = _canonical_json(identity_payload)
    manifest_id = hashlib.sha256(identity_json.encode()).hexdigest()
    manifest_payload = {
        **identity_payload,
        "manifest_id": manifest_id,
        "components": {
            component.component_id: {
                "content_hash": component.content_hash,
                "prompt_name": component.prompt_name,
                "prompt_reference": component.prompt_reference,
                "prompt_version": component.prompt_version,
                "source_paths": list(component.source_paths),
            }
            for component in ordered_components
        },
    }
    return ConfigurationManifest(
        profile=profile,
        manifest_id=manifest_id,
        components=ordered_components,
        content=_compact_json(manifest_payload),
    )


def manifest_from_content(content: str) -> ConfigurationManifest:
    """Rehydrate a provider manifest prompt for arbitrary comparisons."""
    payload = json.loads(content)
    components = tuple(
        RegisteredComponent(
            component_id=component_id,
            content_hash=component["content_hash"],
            prompt_name=component["prompt_name"],
            prompt_version=int(component["prompt_version"]),
            prompt_reference=component.get(
                "prompt_reference",
                f"{component['prompt_name']}:{component['prompt_version']}",
            ),
            source_paths=tuple(component["source_paths"]),
        )
        for component_id, component in sorted(payload["components"].items())
    )
    return ConfigurationManifest(
        profile=payload["profile"],
        manifest_id=payload["manifest_id"],
        components=components,
        content=_compact_json(payload),
    )


def compare_manifests(
    baseline: ConfigurationManifest | None,
    current: ConfigurationManifest,
) -> ConfigurationChanges:
    """Classify component changes and render a concise framework-facing note."""
    baseline_components = _components_by_id(baseline)
    current_components = _components_by_id(current)
    baseline_ids = set(baseline_components)
    current_ids = set(current_components)
    added = tuple(sorted(current_ids - baseline_ids))
    removed = tuple(sorted(baseline_ids - current_ids))
    shared_ids = baseline_ids & current_ids
    modified = tuple(
        sorted(
            component_id
            for component_id in shared_ids
            if baseline_components[component_id].content_hash
            != current_components[component_id].content_hash
        )
    )
    unchanged = tuple(sorted(shared_ids - set(modified)))
    summary = _render_summary(
        baseline_components,
        current_components,
        added,
        removed,
        modified,
    )
    return ConfigurationChanges(
        baseline=baseline,
        current=current,
        added=added,
        removed=removed,
        modified=modified,
        unchanged=unchanged,
        summary=summary,
    )


def _components_by_id(
    manifest: ConfigurationManifest | None,
) -> dict[str, RegisteredComponent]:
    if manifest is None:
        return {}
    return {component.component_id: component for component in manifest.components}


def _render_summary(
    baseline: dict[str, RegisteredComponent],
    current: dict[str, RegisteredComponent],
    added: tuple[str, ...],
    removed: tuple[str, ...],
    modified: tuple[str, ...],
) -> str:
    sections = []
    if modified:
        lines = [
            f"  {component_id}: v{baseline[component_id].prompt_version} -> "
            f"v{current[component_id].prompt_version}"
            for component_id in modified
        ]
        sections.append("Modified:\n" + "\n".join(lines))
    if added:
        sections.append(
            "Added:\n"
            + "\n".join(
                f"  {component_id}: v{current[component_id].prompt_version}"
                for component_id in added
            )
        )
    if removed:
        sections.append(
            "Removed:\n"
            + "\n".join(
                f"  {component_id}: v{baseline[component_id].prompt_version}"
                for component_id in removed
            )
        )
    return "\n\n".join(sections) if sections else "No configuration changes."


def _canonical_json(payload: dict) -> str:
    return json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def _compact_json(payload: dict) -> str:
    return (
        json.dumps(
            payload,
            sort_keys=True,
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n"
    )
