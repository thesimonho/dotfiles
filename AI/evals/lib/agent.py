"""Agent-under-test and judge invocations for the MLflow eval runner.

Each profile shells out to its authenticated interactive CLI so the harness
works with whichever monthly subscription is currently active.
"""

import json
import os
import shutil
import subprocess

from harness_environment import REPOSITORY_ROOT, SUPPORTED_AGENT_PROFILES

CLI_TIMEOUT_SECONDS = 1800


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


def _call_claude(prompt: str, *, has_tools: bool) -> str:
    command = ["claude", "-p", prompt, "--output-format", "json"]
    if not has_tools:
        command.extend(["--tools", "", "--disable-slash-commands"])
    completed_process = _run_cli_command(
        command,
        "Claude",
    )
    try:
        response = json.loads(completed_process.stdout)
    except json.JSONDecodeError as error:
        message = completed_process.stderr.strip() or "Claude returned invalid JSON"
        raise RuntimeError(message) from error
    response_text = response.get("result")
    if completed_process.returncode != 0 or response.get("is_error"):
        raise RuntimeError(response_text or "Claude CLI request failed")
    if not isinstance(response_text, str):
        raise RuntimeError("Claude JSON response did not contain result text")
    return response_text


def _call_codex(prompt: str) -> str:
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
    )
    if completed_process.returncode != 0:
        message = completed_process.stderr.strip() or "Codex CLI request failed"
        raise RuntimeError(message)
    messages = [
        event["item"]["text"]
        for event in _json_lines(completed_process.stdout)
        if event.get("type") == "item.completed"
        and event.get("item", {}).get("type") == "agent_message"
    ]
    if not messages:
        raise RuntimeError("Codex JSONL response did not contain an agent message")
    return messages[-1]


def _json_lines(output: str) -> tuple[dict, ...]:
    try:
        return tuple(json.loads(line) for line in output.splitlines() if line.strip())
    except json.JSONDecodeError as error:
        raise RuntimeError("Codex returned invalid JSONL") from error


def _child_environment() -> dict[str, str]:
    return {
        name: value
        for name, value in os.environ.items()
        if not name.startswith("MLFLOW_")
    }


def _run_cli_command(command: list[str], cli_name: str) -> subprocess.CompletedProcess:
    """Run an authenticated agent CLI with a bounded execution time."""
    try:
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            cwd=str(REPOSITORY_ROOT),
            env=_child_environment(),
            timeout=CLI_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"{cli_name} CLI timed out after {CLI_TIMEOUT_SECONDS} seconds"
        ) from error


def run_agent(prompt: str, profile: str = "claude") -> str:
    """Run one task through the selected authenticated agent CLI."""
    if profile == "codex":
        return _call_codex(prompt)
    if profile == "claude":
        return _call_claude(prompt, has_tools=True)
    raise ValueError(f"unsupported agent profile: {profile}")


def run_judge(prompt: str, profile: str = "claude") -> str:
    """Judge one response through the selected authenticated agent CLI."""
    if profile == "codex":
        return _call_codex(prompt)
    if profile == "claude":
        return _call_claude(prompt, has_tools=False)
    raise ValueError(f"unsupported agent profile: {profile}")
