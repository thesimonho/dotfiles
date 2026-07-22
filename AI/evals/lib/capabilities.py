"""Preflight shared tools, skills, and agents before scored execution."""

from collections.abc import Mapping
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import shutil
from typing import Any

REQUIRED_EVALUATION_TOOLS = ("rtk", "jq", "git", "just", "node", "npm")
REQUIRED_EVALUATION_SKILLS = ("tdd", "verify", "agent-browser")
REQUIRED_EVALUATION_AGENTS = ("frank", "security-reviewer")
REQUIRED_HOMEOPS_TOOLS = ("kubectl", "flux", "dig")


@dataclass(frozen=True)
class CapabilityItem:
    """Resolved path and stable content identity for one capability."""

    path: str
    content_hash: str


@dataclass(frozen=True)
class CapabilitySnapshot:
    """Capabilities proven available to one agent CLI invocation."""

    profile: str
    tools: dict[str, CapabilityItem]
    skills: dict[str, CapabilityItem]
    agents: dict[str, CapabilityItem]


def capability_manifest(
    snapshots: tuple[CapabilitySnapshot, ...],
) -> dict[str, Any]:
    """Build an inspectable, path-redacted identity for proven capabilities."""
    redacted_snapshots = [
        {
            "profile": snapshot.profile,
            "tools": _content_hashes(snapshot.tools),
            "skills": _content_hashes(snapshot.skills),
            "agents": _content_hashes(snapshot.agents),
        }
        for snapshot in snapshots
    ]
    serialized_snapshots = json.dumps(
        redacted_snapshots,
        sort_keys=True,
        separators=(",", ":"),
    )
    return {
        "manifest_hash": hashlib.sha256(serialized_snapshots.encode()).hexdigest(),
        "snapshots": redacted_snapshots,
    }


def probe_capabilities(
    profile: str,
    environment: Mapping[str, str],
    *,
    required_tools: tuple[str, ...],
    required_skills: tuple[str, ...],
    required_agents: tuple[str, ...],
) -> CapabilitySnapshot:
    """Resolve every required capability or fail the environment preflight."""
    home_path = Path(environment["HOME"])
    config_path = _config_path(profile, environment, home_path)
    tools = {
        name: _item_for_path(_required_tool_path(name, environment))
        for name in required_tools
    }
    skills = {
        name: _item_for_path(
            _required_file(
                name,
                tuple(
                    path / name / "SKILL.md"
                    for path in (
                        config_path / "skills",
                        home_path / ".agents" / "skills",
                        home_path / ".claude" / "skills",
                    )
                ),
                "skill",
            )
        )
        for name in required_skills
    }
    agent_extension = "toml" if profile == "codex" else "md"
    agents = {
        name: _item_for_path(
            _required_file(
                name,
                (config_path / "agents" / f"{name}.{agent_extension}",),
                "agent",
            )
        )
        for name in required_agents
    }
    return CapabilitySnapshot(
        profile=profile,
        tools=tools,
        skills=skills,
        agents=agents,
    )


def _config_path(
    profile: str,
    environment: Mapping[str, str],
    home_path: Path,
) -> Path:
    """Resolve the active CLI configuration directory."""
    if profile == "codex":
        return Path(environment.get("CODEX_HOME", home_path / ".codex"))
    if profile == "claude":
        return Path(environment.get("CLAUDE_CONFIG_DIR", home_path / ".claude"))
    raise ValueError(f"unsupported agent profile: {profile}")


def _required_tool_path(name: str, environment: Mapping[str, str]) -> Path:
    """Resolve one executable against the exact child PATH."""
    resolved_path = shutil.which(name, path=environment.get("PATH"))
    if resolved_path is None:
        raise RuntimeError(f"required evaluation tool is unavailable: {name}")
    return Path(resolved_path)


def _required_file(
    name: str,
    candidates: tuple[Path, ...],
    kind: str,
) -> Path:
    """Resolve the first regular file among supported CLI locations."""
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    searched_paths = ", ".join(str(path) for path in candidates)
    raise RuntimeError(
        f"required evaluation {kind} is unavailable: {name}; searched {searched_paths}"
    )


def _item_for_path(path: Path) -> CapabilityItem:
    """Describe a capability without publishing its full content."""
    return CapabilityItem(
        path=str(path.resolve()),
        content_hash=hashlib.sha256(path.read_bytes()).hexdigest(),
    )


def _content_hashes(items: dict[str, CapabilityItem]) -> dict[str, str]:
    """Remove host paths while retaining each logical capability identity."""
    return {name: item.content_hash for name, item in sorted(items.items())}
