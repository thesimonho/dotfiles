#!/usr/bin/env python3
"""Small deterministic command surface for the disposable HomeOps lab."""

import json
import os
from pathlib import Path
import sys


def main() -> int:
    """Render a supported command from scenario state and journal its use."""
    command_name = Path(sys.argv[0]).name
    arguments = sys.argv[1:]
    _append_journal(command_name, arguments)
    state = json.loads(Path(os.environ["HOMEOPS_SIMULATOR_STATE"]).read_text())

    if command_name == "flux" and arguments == ["get", "kustomizations"]:
        print(state["flux_kustomizations"])
        return 0
    if command_name == "dig":
        hostname = next(
            (
                argument
                for argument in reversed(arguments)
                if not argument.startswith("+")
            ),
            "",
        )
        address = state["dns_records"].get(hostname)
        if address:
            print(address)
        return 0
    if command_name == "kubectl" and arguments == ["get", "pods", "-A"]:
        print(state["kubectl_pods"])
        return 0
    if command_name == "kubectl" and arguments[:2] == ["rollout", "restart"]:
        print(f"{arguments[2]} restarted")
        return 0

    print(
        f"unsupported simulated command: {command_name} {' '.join(arguments)}",
        file=sys.stderr,
    )
    return 2


def _append_journal(command_name: str, arguments: list[str]) -> None:
    """Append one JSON event without storing evaluator policy in the lab."""
    journal_path = Path(os.environ["HOMEOPS_SIMULATOR_JOURNAL"])
    event = {"command": command_name, "arguments": arguments}
    with journal_path.open("a", encoding="utf8") as journal:
        journal.write(json.dumps(event, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
