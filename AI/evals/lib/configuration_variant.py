"""Controlled active-component variants for causal instruction comparisons."""

from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
import os
from pathlib import Path
import secrets
import shutil
import tempfile
import tomllib
from typing import Literal

from configuration_components import ConfigComponent

type VariantName = Literal["treatment", "control"]


@dataclass(frozen=True)
class ConfigurationVariant:
    """One active configuration arm in a paired comparison."""

    name: VariantName
    components: tuple[ConfigComponent, ...]
    excluded_component_id: str | None = None


@dataclass(frozen=True)
class PreparedProfileConfiguration:
    """Temporary client configuration containing one active instruction set."""

    root: Path
    environment: dict[str, str]
    agent_definition_canary: str


def comparison_variants(
    components: tuple[ConfigComponent, ...],
    excluded_component_id: str,
) -> tuple[ConfigurationVariant, ConfigurationVariant]:
    """Return full treatment and single-component-ablated control arms."""
    if not excluded_component_id.startswith("instruction/"):
        raise ValueError("comparisons currently support instruction components only")
    component_ids = {component.component_id for component in components}
    if excluded_component_id not in component_ids:
        raise ValueError(f"unknown comparison component: {excluded_component_id}")
    control_components = tuple(
        component
        for component in components
        if component.component_id != excluded_component_id
    )
    return (
        ConfigurationVariant(name="treatment", components=components),
        ConfigurationVariant(
            name="control",
            components=control_components,
            excluded_component_id=excluded_component_id,
        ),
    )


@contextmanager
def prepare_variant_profile(
    profile: str,
    variant: ConfigurationVariant,
    *,
    source_config_root: Path | None = None,
    agent_definition_canary: str | None = None,
) -> Iterator[PreparedProfileConfiguration]:
    """Assemble an authenticated, hook-free profile for one comparison arm."""
    source_root = source_config_root or _active_config_root(profile)
    with tempfile.TemporaryDirectory(
        prefix=f"agent-eval-{profile}-config-"
    ) as directory:
        profile_root = Path(directory) / profile
        profile_root.mkdir()
        selected_agent_definition_canary = (
            agent_definition_canary or new_agent_definition_canary()
        )
        if profile == "codex":
            _prepare_codex_profile(
                source_root,
                profile_root,
                variant,
                selected_agent_definition_canary,
            )
            environment = {"CODEX_HOME": str(profile_root)}
        elif profile == "claude":
            _prepare_claude_profile(
                source_root,
                profile_root,
                variant,
                selected_agent_definition_canary,
            )
            environment = {"CLAUDE_CONFIG_DIR": str(profile_root)}
        else:
            raise ValueError(f"unsupported agent profile: {profile}")
        yield PreparedProfileConfiguration(
            root=profile_root,
            environment=environment,
            agent_definition_canary=selected_agent_definition_canary,
        )


def _active_config_root(profile: str) -> Path:
    """Resolve the authenticated source profile without guessing in callers."""
    home_root = Path(os.environ["HOME"])
    if profile == "codex":
        return Path(os.environ.get("CODEX_HOME", home_root / ".codex"))
    if profile == "claude":
        return Path(os.environ.get("CLAUDE_CONFIG_DIR", home_root / ".claude"))
    raise ValueError(f"unsupported agent profile: {profile}")


def _prepare_codex_profile(
    source_root: Path,
    profile_root: Path,
    variant: ConfigurationVariant,
    agent_definition_canary: str,
) -> None:
    """Copy Codex runtime identity and render only active prose instructions."""
    _copy_required_files(source_root, profile_root, ("auth.json", "config.toml"))
    _copy_optional_files(source_root, profile_root, ("installation_id",))
    _copy_required_directories(source_root, profile_root, ("agents",))
    _link_required_directories(source_root, profile_root, ("skills",))
    _link_optional_directories(source_root, profile_root, ("plugins", "rules"))
    _instrument_codex_agent(
        profile_root / "agents" / "frank.toml",
        agent_definition_canary,
    )
    (profile_root / "AGENTS.md").write_text(_instruction_document(variant))


def _prepare_claude_profile(
    source_root: Path,
    profile_root: Path,
    variant: ConfigurationVariant,
    agent_definition_canary: str,
) -> None:
    """Copy Claude authentication and expose active instructions as rules."""
    _copy_required_files(source_root, profile_root, (".credentials.json",))
    _copy_required_directories(source_root, profile_root, ("agents",))
    _link_required_directories(source_root, profile_root, ("skills",))
    _instrument_claude_agent(
        profile_root / "agents" / "frank.md",
        agent_definition_canary,
    )
    rules_root = profile_root / "rules"
    rules_root.mkdir()
    for component in _instruction_components(variant):
        rule_name = component.component_id.removeprefix("instruction/")
        (rules_root / f"{rule_name}.md").write_text(component.content)


def _instruction_document(variant: ConfigurationVariant) -> str:
    """Render stable Codex global instructions from selected components."""
    return (
        "\n".join(
            component.content.rstrip() for component in _instruction_components(variant)
        )
        + "\n"
    )


def _instruction_components(
    variant: ConfigurationVariant,
) -> tuple[ConfigComponent, ...]:
    """Return only prose instructions; agents remain opt-in capabilities."""
    return tuple(
        component
        for component in variant.components
        if component.component_id.startswith("instruction/")
    )


def _copy_required_files(
    source_root: Path,
    destination_root: Path,
    names: tuple[str, ...],
) -> None:
    """Copy sensitive runtime files so variants never mutate the live profile."""
    for name in names:
        source_path = source_root / name
        if not source_path.is_file():
            raise RuntimeError(
                f"required {source_root.name} config file is missing: {name}"
            )
        shutil.copy2(source_path, destination_root / name)


def _copy_optional_files(
    source_root: Path,
    destination_root: Path,
    names: tuple[str, ...],
) -> None:
    """Copy optional runtime identity files when the active client has them."""
    for name in names:
        source_path = source_root / name
        if source_path.is_file():
            shutil.copy2(source_path, destination_root / name)


def _copy_required_directories(
    source_root: Path,
    destination_root: Path,
    names: tuple[str, ...],
) -> None:
    """Materialize capabilities that the client may reject through symlinks."""
    for name in names:
        source_path = source_root / name
        if not source_path.is_dir():
            raise RuntimeError(
                f"required capability directory is missing: {source_path}"
            )
        shutil.copytree(source_path.resolve(), destination_root / name)


def _link_required_directories(
    source_root: Path,
    destination_root: Path,
    names: tuple[str, ...],
) -> None:
    """Share immutable capability directories equally across both arms."""
    for name in names:
        source_path = source_root / name
        if not source_path.is_dir():
            raise RuntimeError(
                f"required capability directory is missing: {source_path}"
            )
        (destination_root / name).symlink_to(
            source_path.resolve(), target_is_directory=True
        )


def _link_optional_directories(
    source_root: Path,
    destination_root: Path,
    names: tuple[str, ...],
) -> None:
    """Share optional non-prose client policy directories when available."""
    for name in names:
        source_path = source_root / name
        if source_path.is_dir():
            (destination_root / name).symlink_to(
                source_path.resolve(),
                target_is_directory=True,
            )


def new_agent_definition_canary() -> str:
    """Create a run-local marker that cannot be learned from the case prompt."""
    return f"FRANK_DEFINITION_LOADED_{secrets.token_hex(12).upper()}"


def _instrument_codex_agent(path: Path, canary: str) -> None:
    """Append a harmless identity footer inside Frank's developer instructions."""
    content = path.read_text()
    closing_delimiter = content.rfind('"""')
    if closing_delimiter < 0:
        raise RuntimeError(f"Codex agent lacks developer instruction block: {path}")
    instruction = _agent_definition_probe_instruction(canary)
    instrumented = (
        content[:closing_delimiter] + instruction + content[closing_delimiter:]
    )
    tomllib.loads(instrumented)
    path.write_text(instrumented)


def _instrument_claude_agent(path: Path, canary: str) -> None:
    """Append the same provider-neutral identity footer to Claude's Frank agent."""
    if not path.is_file():
        raise RuntimeError(f"required Claude agent is missing: {path}")
    path.write_text(
        path.read_text().rstrip() + "\n" + _agent_definition_probe_instruction(canary)
    )


def _agent_definition_probe_instruction(canary: str) -> str:
    """Render the provider-neutral exact-footer instruction."""
    return (
        "\nEvaluation identity probe: end your response to the parent with this "
        f"exact final line, without Markdown formatting: {canary}\n"
    )
