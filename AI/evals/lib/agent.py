"""Agent-under-test and judge invocations for the MLflow eval runner.

Each profile shells out to its authenticated interactive CLI so the harness
works with whichever monthly subscription is currently active.
"""

import json
import os
import shlex
import shutil
import subprocess
from dataclasses import dataclass

from agent_environment import build_child_environment
from agent_execution_context import AgentExecutionContext
from harness_environment import REPOSITORY_ROOT, SUPPORTED_AGENT_PROFILES

CLI_TIMEOUT_SECONDS = 1800


@dataclass(frozen=True)
class AgentResult:
    """Final response paired with normalized behavioral evidence."""

    response: str
    shell_commands: tuple[str, ...]


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
) -> AgentResult:
    command = [
        "claude",
        "-p",
        prompt,
        "--output-format",
        "stream-json",
        "--verbose",
    ]
    if not has_tools:
        command.extend(["--tools", "", "--disable-slash-commands"])
    completed_process = _run_cli_command(
        command,
        "Claude",
        context,
    )
    if completed_process.returncode != 0:
        message = completed_process.stderr.strip() or "Claude CLI request failed"
        raise RuntimeError(message)
    return claude_result_from_output(completed_process.stdout)


def claude_result_from_output(output: str) -> AgentResult:
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
    return AgentResult(response=response_text, shell_commands=shell_commands)


def _call_codex(prompt: str, context: AgentExecutionContext) -> AgentResult:
    command = [
        "codex",
        "exec",
        "--ephemeral",
        "--sandbox",
        "read-only",
        "--json",
        prompt,
    ]
    completed_process = _run_cli_command(
        command,
        "Codex",
        context,
    )
    if completed_process.returncode != 0:
        message = completed_process.stderr.strip() or "Codex CLI request failed"
        raise RuntimeError(message)
    return codex_result_from_output(completed_process.stdout)


def codex_result_from_output(output: str) -> AgentResult:
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
    return AgentResult(response=messages[-1], shell_commands=shell_commands)


def normalize_shell_command(command: str) -> str:
    """Remove the CLI's shell launcher while preserving agent-authored syntax."""
    try:
        tokens = shlex.split(command)
    except ValueError:
        return command
    if len(tokens) >= 3 and os.path.basename(tokens[0]) in {"bash", "sh", "zsh"}:
        if tokens[1] in {"-c", "-lc"}:
            return tokens[2]
    return command


def _json_lines(output: str) -> tuple[dict, ...]:
    try:
        return tuple(json.loads(line) for line in output.splitlines() if line.strip())
    except json.JSONDecodeError as error:
        raise RuntimeError("Codex returned invalid JSONL") from error


def _run_cli_command(
    command: list[str],
    cli_name: str,
    context: AgentExecutionContext,
) -> subprocess.CompletedProcess:
    """Run an authenticated agent CLI with a bounded execution time."""
    try:
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            cwd=str(REPOSITORY_ROOT),
            env=build_child_environment(os.environ, context),
            timeout=CLI_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"{cli_name} CLI timed out after {CLI_TIMEOUT_SECONDS} seconds"
        ) from error


def run_agent(
    prompt: str,
    context: AgentExecutionContext,
    profile: str = "claude",
) -> AgentResult:
    """Run one task through the selected authenticated agent CLI."""
    if profile == "codex":
        return _call_codex(prompt, context)
    if profile == "claude":
        return _call_claude(prompt, context, has_tools=True)
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
