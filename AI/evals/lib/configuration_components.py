"""Discover deterministic, allowlisted snapshots of effective agent config."""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import Path

from harness_environment import REPOSITORY_ROOT, SUPPORTED_AGENT_PROFILES
from harness_identity import PROMPT_NAMESPACE_PREFIX


@dataclass(frozen=True)
class ConfigComponent:
    """One independently versioned unit of effective agent configuration."""

    component_id: str
    registry_name: str
    content: str
    content_hash: str
    source_paths: tuple[str, ...]


def discover_agent_components(
    profile: str,
    repository_root: Path = REPOSITORY_ROOT,
) -> tuple[ConfigComponent, ...]:
    """Return an agent profile's allowlisted config in stable component-ID order."""
    if profile not in SUPPORTED_AGENT_PROFILES:
        raise ValueError(f"unsupported agent profile: {profile}")
    instruction_components = _discover_single_file_components(
        repository_root,
        "AI/instructions/fragments",
        "*.md",
        "instruction",
    )
    agent_components = _discover_single_file_components(
        repository_root,
        "AI/agents",
        "*.md",
        "agent",
    )
    skill_components = _discover_skill_components(repository_root)
    components = [*instruction_components, *agent_components, *skill_components]
    components_by_id = {component.component_id: component for component in components}
    if len(components_by_id) != len(components):
        raise ValueError("configuration component IDs must be unique")
    return tuple(
        components_by_id[component_id] for component_id in sorted(components_by_id)
    )


def _discover_single_file_components(
    repository_root: Path,
    relative_directory: str,
    pattern: str,
    component_kind: str,
) -> list[ConfigComponent]:
    directory = repository_root / relative_directory
    if not directory.exists():
        return []
    components = []
    for path in sorted(directory.glob(pattern)):
        if path.is_symlink():
            raise ValueError(f"configuration files must not be symlinks: {path}")
        if not path.is_file():
            continue
        components.append(
            _component_from_content(
                repository_root,
                f"{component_kind}/{path.stem}",
                _normalized_text(path),
                (path,),
            )
        )
    return components


def _discover_skill_components(repository_root: Path) -> list[ConfigComponent]:
    """Track each custom skill through its SKILL.md interface document."""
    directory = repository_root / "AI/skills"
    if not directory.exists():
        return []
    components = []
    for skill_directory in sorted(directory.iterdir()):
        if skill_directory.name.startswith(".") or not skill_directory.is_dir():
            continue
        skill_file = skill_directory / "SKILL.md"
        if skill_directory.is_symlink() or skill_file.is_symlink():
            raise ValueError(
                f"configuration files must not be symlinks: {skill_file}"
            )
        if not skill_file.is_file():
            continue
        components.append(
            _component_from_content(
                repository_root,
                f"skill/{skill_directory.name}",
                _normalized_text(skill_file),
                (skill_file,),
            )
        )
    return components


def _component_from_content(
    repository_root: Path,
    component_id: str,
    content: str,
    source_paths: tuple[Path, ...],
) -> ConfigComponent:
    normalized_sources = tuple(
        source_path.relative_to(repository_root).as_posix()
        for source_path in source_paths
    )
    content_hash = hashlib.sha256(content.encode()).hexdigest()
    return ConfigComponent(
        component_id=component_id,
        registry_name=_registry_name(component_id),
        content=content,
        content_hash=content_hash,
        source_paths=normalized_sources,
    )


def _registry_name(component_id: str) -> str:
    normalized_id = re.sub(r"[^a-zA-Z0-9-]+", "--", component_id).strip("-").lower()
    identity_suffix = hashlib.sha256(component_id.encode()).hexdigest()[:10]
    return f"{PROMPT_NAMESPACE_PREFIX}{normalized_id}--{identity_suffix}"


def _normalized_text(path: Path) -> str:
    return path.read_text().replace("\r\n", "\n").replace("\r", "\n")
