#!/usr/bin/env python3
"""Merge declarative Codex settings into Codex's writable user config."""

from __future__ import annotations

import argparse
import json
import os
import tempfile
from collections.abc import Mapping, MutableMapping
from pathlib import Path
from typing import Any

import tomlkit  # pyright: ignore[reportMissingImports]


KeyPath = tuple[str, ...]


def parse_arguments() -> argparse.Namespace:
    """Parse paths used by the config reconciliation operation."""
    parser = argparse.ArgumentParser(
        description="Apply tracked Codex settings while preserving local-only state."
    )
    parser.add_argument("--managed", type=Path, required=True)
    parser.add_argument("--local", type=Path, required=True)
    parser.add_argument("--state", type=Path, required=True)
    return parser.parse_args()


def read_toml(path: Path) -> Any:
    """Read a TOML document, returning an empty document when it is absent."""
    if not path.exists():
        return tomlkit.document()

    return tomlkit.parse(path.read_text(encoding="utf-8"))


def collect_leaf_paths(value: Any, prefix: KeyPath = ()) -> set[KeyPath]:
    """Return the concrete value paths owned by a TOML document."""
    if isinstance(value, Mapping) and value:
        paths: set[KeyPath] = set()
        for key, child in value.items():
            paths.update(collect_leaf_paths(child, (*prefix, str(key))))
        return paths

    return {prefix} if prefix else set()


def read_managed_paths(path: Path) -> set[KeyPath]:
    """Read the paths managed during the previous reconciliation."""
    if not path.exists():
        return set()

    serialized_paths = json.loads(path.read_text(encoding="utf-8"))
    return {tuple(path_parts) for path_parts in serialized_paths}


def remove_path(document: Any, path: KeyPath) -> None:
    """Remove one previously managed value and prune empty parent tables."""
    parents: list[tuple[MutableMapping[str, Any], str]] = []
    current = document

    for key in path[:-1]:
        if not isinstance(current, MutableMapping) or key not in current:
            return
        parents.append((current, key))
        current = current[key]

    if not path or not isinstance(current, MutableMapping):
        return

    current.pop(path[-1], None)

    for parent, key in reversed(parents):
        child = parent.get(key)
        if not isinstance(child, Mapping) or child:
            break
        parent.pop(key, None)


def overlay_managed_values(local: Any, managed: Any) -> None:
    """Recursively overlay managed values without deleting local-only siblings."""
    for key, managed_value in managed.items():
        local_value = local.get(key)
        values_are_tables = isinstance(managed_value, Mapping) and isinstance(
            local_value, Mapping
        )

        if values_are_tables:
            overlay_managed_values(local_value, managed_value)
            continue

        local[key] = managed_value


def write_atomically(path: Path, content: str, mode: int) -> None:
    """Replace a file atomically without following an existing symlink."""
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent, prefix=f".{path.name}."
    )
    temporary_path = Path(temporary_name)

    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as temporary_file:
            temporary_file.write(content)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.chmod(temporary_path, mode)
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


def serialize_paths(paths: set[KeyPath]) -> str:
    """Serialize managed paths deterministically for future reconciliation."""
    return json.dumps([list(path) for path in sorted(paths)], indent=2) + "\n"


def reconcile_config(managed_path: Path, local_path: Path, state_path: Path) -> None:
    """Apply managed settings and retain values owned only by local Codex state."""
    managed = read_toml(managed_path)
    local = read_toml(local_path)
    previous_managed_paths = read_managed_paths(state_path)
    current_managed_paths = collect_leaf_paths(managed)
    original_local_values = local.unwrap()

    for path in sorted(previous_managed_paths, key=len, reverse=True):
        remove_path(local, path)

    overlay_managed_values(local, managed)

    if local.unwrap() != original_local_values or local_path.is_symlink():
        write_atomically(local_path, tomlkit.dumps(local), 0o600)

    serialized_paths = serialize_paths(current_managed_paths)
    existing_state = (
        state_path.read_text(encoding="utf-8") if state_path.exists() else None
    )
    if serialized_paths != existing_state:
        write_atomically(state_path, serialized_paths, 0o600)


def main() -> None:
    """Run Codex configuration reconciliation."""
    arguments = parse_arguments()
    reconcile_config(arguments.managed, arguments.local, arguments.state)


if __name__ == "__main__":
    main()
