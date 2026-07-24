"""Agent-under-test and judge invocations for the MLflow eval runner.

Each profile shells out to its authenticated interactive CLI so the harness
works with whichever monthly subscription is currently active.
"""

import json
import os
import shutil
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

from agent_evidence import (
    AgentEvent,
    TokenUsage,
    claude_evidence,
    codex_evidence,
    normalize_shell_command,
)
from agent_event_contract import AgentEventCoverage
from agent_environment import build_child_environment
from agent_execution_context import AgentExecutionContext
from harness_environment import REPOSITORY_ROOT, SUPPORTED_AGENT_PROFILES

CLI_TIMEOUT_SECONDS = 1800
type WorkspaceAccess = Literal["read-only", "workspace-write"]


@dataclass(frozen=True)
class AgentResult:
    """Final response paired with normalized behavioral evidence."""

    response: str
    shell_commands: tuple[str, ...]
    events: tuple[AgentEvent, ...]
    token_usage: TokenUsage
    model_ids: tuple[str, ...]
    event_coverage: AgentEventCoverage
    invocation_seconds: float


@dataclass(frozen=True)
class CompletedAgentProcess:
    """Completed CLI process paired with harness-measured wall-clock time."""

    returncode: int
    stdout: str
    stderr: str
    invocation_seconds: float


def resolve_agent_profile(requested_profile: str) -> str:
    """Resolve an explicit profile or the only CLI available on PATH."""
    if requested_profile != "auto":
        if requested_profile not in SUPPORTED_AGENT_PROFILES:
            raise ValueError(f"unsupported agent profile: {requested_profile}")
        if shutil.which(requested_profile) is None:
            raise RuntimeError(f"{requested_profile} CLI is not available on PATH")
        return requested_profile
    available_profiles = [
        profile for profile in SUPPORTED_AGENT_PROFILES if shutil.which(profile)
    ]
    if len(available_profiles) == 1:
        return available_profiles[0]
    if not available_profiles:
        raise RuntimeError("neither Codex nor Claude CLI is available on PATH")
    raise RuntimeError("both Codex and Claude are installed; select one with --agent")


def _call_claude(
    prompt: str,
    context: AgentExecutionContext,
    *,
    has_tools: bool,
    workspace_path: Path = REPOSITORY_ROOT,
    workspace_access: WorkspaceAccess = "read-only",
    environment_overrides: dict[str, str] | None = None,
    additional_writable_paths: tuple[Path, ...] = (),
    agent_definition_canary: str | None = None,
) -> AgentResult:
    sandbox_settings = claude_sandbox_settings(additional_writable_paths)
    command = [
        "claude",
        "-p",
        prompt,
        "--output-format",
        "stream-json",
        "--verbose",
        "--permission-mode",
        "plan" if workspace_access == "read-only" else "acceptEdits",
        "--setting-sources",
        "",
        "--settings",
        json.dumps(sandbox_settings),
    ]
    if not has_tools:
        command.extend(["--tools", "", "--disable-slash-commands"])
    completed_process = _run_cli_command(
        command,
        "Claude",
        context,
        workspace_path=workspace_path,
        environment_overrides=environment_overrides,
    )
    if completed_process.returncode != 0:
        message = completed_process.stderr.strip() or "Claude CLI request failed"
        raise RuntimeError(message)
    return claude_result_from_output(
        completed_process.stdout,
        invocation_seconds=completed_process.invocation_seconds,
        agent_definition_canary=agent_definition_canary,
    )


def claude_result_from_output(
    output: str,
    invocation_seconds: float = 0.0,
    agent_definition_canary: str | None = None,
) -> AgentResult:
    """Normalize Claude stream JSON into response and Bash command evidence."""
    events = _json_lines(output)
    result_events = [event for event in events if event.get("type") == "result"]
    if not result_events:
        raise RuntimeError("Claude stream did not contain a result event")
    result_event = result_events[-1]
    response_text = result_event.get("result")
    if result_event.get("is_error") or not isinstance(response_text, str):
        raise RuntimeError(response_text or "Claude CLI request failed")
    shell_commands = tuple(
        content["input"]["command"]
        for event in events
        if event.get("type") == "assistant"
        for content in event.get("message", {}).get("content", [])
        if content.get("type") == "tool_use"
        and content.get("name") == "Bash"
        and isinstance(content.get("input", {}).get("command"), str)
    )
    agent_events, token_usage, model_ids, event_coverage = claude_evidence(
        events,
        result_event,
        agent_definition_canary,
    )
    return AgentResult(
        response=response_text,
        shell_commands=shell_commands,
        events=agent_events,
        token_usage=token_usage,
        model_ids=model_ids,
        event_coverage=event_coverage,
        invocation_seconds=invocation_seconds,
    )


def _call_codex(
    prompt: str,
    context: AgentExecutionContext,
    *,
    workspace_path: Path = REPOSITORY_ROOT,
    workspace_access: WorkspaceAccess = "read-only",
    environment_overrides: dict[str, str] | None = None,
    additional_writable_paths: tuple[Path, ...] = (),
    agent_definition_canary: str | None = None,
) -> AgentResult:
    command = [
        "codex",
        "exec",
        "--ephemeral",
        *codex_sandbox_arguments(),
        "--sandbox",
        workspace_access,
    ]
    for writable_path in additional_writable_paths:
        command.extend(["--add-dir", str(writable_path)])
    command.extend(["--json", prompt])
    completed_process = _run_cli_command(
        command,
        "Codex",
        context,
        workspace_path=workspace_path,
        environment_overrides=environment_overrides,
    )
    if completed_process.returncode != 0:
        message = completed_process.stderr.strip() or "Codex CLI request failed"
        raise RuntimeError(message)
    return codex_result_from_output(
        completed_process.stdout,
        invocation_seconds=completed_process.invocation_seconds,
        agent_definition_canary=agent_definition_canary,
    )


def codex_result_from_output(
    output: str,
    invocation_seconds: float = 0.0,
    agent_definition_canary: str | None = None,
) -> AgentResult:
    """Normalize Codex JSONL into response text and shell command evidence."""
    events = _json_lines(output)
    messages = [
        event["item"]["text"]
        for event in events
        if event.get("type") == "item.completed"
        and event.get("item", {}).get("type") == "agent_message"
    ]
    if not messages:
        raise RuntimeError("Codex JSONL response did not contain an agent message")
    shell_commands = tuple(
        normalize_shell_command(event["item"]["command"])
        for event in events
        if event.get("type") == "item.completed"
        and event.get("item", {}).get("type") == "command_execution"
        and isinstance(event["item"].get("command"), str)
    )
    agent_events, token_usage, model_ids, event_coverage = codex_evidence(
        events,
        agent_definition_canary,
    )
    return AgentResult(
        response=messages[-1],
        shell_commands=shell_commands,
        events=agent_events,
        token_usage=token_usage,
        model_ids=model_ids,
        event_coverage=event_coverage,
        invocation_seconds=invocation_seconds,
    )


def codex_sandbox_arguments() -> tuple[str, str]:
    """Disable network for commands inside Codex's native OS sandbox."""
    return ("-c", "sandbox_workspace_write.network_access=false")


def claude_sandbox_settings(
    additional_writable_paths: tuple[Path, ...],
) -> dict[str, Any]:
    """Require Claude's OS sandbox and remove its unsandboxed escape hatch."""
    return {
        "sandbox": {
            "enabled": True,
            "failIfUnavailable": True,
            "autoAllowBashIfSandboxed": True,
            "allowUnsandboxedCommands": False,
            "excludedCommands": [],
            "filesystem": {
                "allowWrite": [str(path) for path in additional_writable_paths],
                "denyRead": ["~/.kube", "~/.aws", "~/.config/gcloud", "~/.ssh"],
            },
            "network": {"allowedDomains": []},
        }
    }


def _json_lines(output: str) -> tuple[dict, ...]:
    try:
        return tuple(json.loads(line) for line in output.splitlines() if line.strip())
    except json.JSONDecodeError as error:
        raise RuntimeError("Codex returned invalid JSONL") from error


def _run_cli_command(
    command: list[str],
    cli_name: str,
    context: AgentExecutionContext,
    *,
    workspace_path: Path = REPOSITORY_ROOT,
    environment_overrides: dict[str, str] | None = None,
) -> CompletedAgentProcess:
    """Run an authenticated agent CLI with a bounded execution time."""
    invocation_started_at = time.perf_counter()
    try:
        completed_process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            cwd=str(workspace_path),
            env=build_child_environment(
                os.environ,
                context,
                overrides=environment_overrides,
            ),
            timeout=CLI_TIMEOUT_SECONDS,
        )
        return CompletedAgentProcess(
            returncode=completed_process.returncode,
            stdout=completed_process.stdout,
            stderr=completed_process.stderr,
            invocation_seconds=time.perf_counter() - invocation_started_at,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"{cli_name} CLI timed out after {CLI_TIMEOUT_SECONDS} seconds"
        ) from error


def run_agent(
    prompt: str,
    context: AgentExecutionContext,
    profile: str = "claude",
    workspace_path: Path = REPOSITORY_ROOT,
    workspace_access: WorkspaceAccess = "read-only",
    environment_overrides: dict[str, str] | None = None,
    additional_writable_paths: tuple[Path, ...] = (),
    agent_definition_canary: str | None = None,
) -> AgentResult:
    """Run one task through the selected authenticated agent CLI."""
    if profile == "codex":
        return _call_codex(
            prompt,
            context,
            workspace_path=workspace_path,
            workspace_access=workspace_access,
            environment_overrides=environment_overrides,
            additional_writable_paths=additional_writable_paths,
            agent_definition_canary=agent_definition_canary,
        )
    if profile == "claude":
        return _call_claude(
            prompt,
            context,
            has_tools=True,
            workspace_path=workspace_path,
            workspace_access=workspace_access,
            environment_overrides=environment_overrides,
            additional_writable_paths=additional_writable_paths,
            agent_definition_canary=agent_definition_canary,
        )
    raise ValueError(f"unsupported agent profile: {profile}")


def run_judge(
    prompt: str,
    context: AgentExecutionContext,
    profile: str = "claude",
) -> str:
    """Judge one response through the selected authenticated agent CLI."""
    if profile == "codex":
        return _call_codex(prompt, context).response
    if profile == "claude":
        return _call_claude(prompt, context, has_tools=False).response
    raise ValueError(f"unsupported agent profile: {profile}")
