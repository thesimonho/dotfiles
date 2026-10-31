#!/usr/bin/env python3
"""Reconcile tracked MCP entries without owning Claude's remaining user state."""

import json
import os
import sys
import tempfile
from pathlib import Path


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, indent=2)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    managed_path, local_path, state_path = map(Path, sys.argv[1:])
    managed = json.loads(managed_path.read_text())["mcpServers"]
    local = json.loads(local_path.read_text()) if local_path.exists() else {}
    previous = json.loads(state_path.read_text()) if state_path.exists() else []
    servers = local.setdefault("mcpServers", {})
    if not isinstance(managed, dict) or not isinstance(servers, dict):
        raise TypeError("mcpServers must be an object")
    for name in previous:
        if name not in managed:
            servers.pop(name, None)
    servers.update(managed)
    write_json(local_path, local)
    write_json(state_path, sorted(managed))


if __name__ == "__main__":
    main()
