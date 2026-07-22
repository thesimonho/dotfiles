"""Least-privilege subprocess environment construction for agent CLIs."""

from collections.abc import Mapping

from agent_execution_context import AgentExecutionContext

PASSTHROUGH_CONTROL_VARIABLE = "AGENT_EVAL_PASSTHROUGH_ENV"
SAFE_ENVIRONMENT_VARIABLES = (
    "PATH",
    "HOME",
    "USER",
    "LOGNAME",
    "SHELL",
    "LANG",
    "LC_ALL",
    "LC_CTYPE",
    "TERM",
    "COLORTERM",
    "TMPDIR",
    "XDG_CONFIG_HOME",
    "XDG_CACHE_HOME",
    "XDG_DATA_HOME",
    "CLAUDE_CONFIG_DIR",
    "CODEX_HOME",
)


def build_child_environment(
    parent_environment: Mapping[str, str],
    context: AgentExecutionContext,
    overrides: Mapping[str, str] | None = None,
) -> dict[str, str]:
    """Return only runtime essentials plus explicitly named integrations."""
    allowed_names: set[str] = set(SAFE_ENVIRONMENT_VARIABLES)
    allowed_names.update(_explicit_passthrough_names(parent_environment))
    child_environment = {
        name: parent_environment[name]
        for name in allowed_names
        if name in parent_environment
    }
    child_environment.update(overrides or {})
    child_environment["OTEL_RESOURCE_ATTRIBUTES"] = context.otel_resource_attributes()
    return child_environment


def _explicit_passthrough_names(
    parent_environment: Mapping[str, str],
) -> tuple[str, ...]:
    """Parse opt-in variable names without copying the control variable itself."""
    configured_names = parent_environment.get(PASSTHROUGH_CONTROL_VARIABLE, "")
    return tuple(name.strip() for name in configured_names.split(",") if name.strip())
