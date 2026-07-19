"""Behavior tests for Claude CLI transport handling."""

import json
import os
import sys
import unittest
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import patch

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

import agent  # noqa: E402


class AgentTests(unittest.TestCase):
    """Verify eval scorers receive assistant text rather than CLI envelopes."""

    @patch("agent.shutil.which")
    def test_auto_selects_the_only_installed_cli(self, which):
        which.side_effect = lambda command: "/bin/codex" if command == "codex" else None

        self.assertEqual(agent.resolve_agent_profile("auto"), "codex")

    @patch("agent.subprocess.run")
    def test_returns_the_final_codex_agent_message(self, run):
        run.return_value = CompletedProcess(
            args=["codex"],
            returncode=0,
            stdout=(
                '{"type":"thread.started","thread_id":"thread-1"}\n'
                '{"type":"item.completed","item":{"type":"agent_message","text":"4"}}\n'
                '{"type":"turn.completed"}\n'
            ),
            stderr="",
        )

        self.assertEqual(agent.run_agent("2+2", profile="codex"), "4")
        self.assertEqual(run.call_args.kwargs["timeout"], 1800)

    @patch("agent.subprocess.run")
    def test_surfaces_agent_cli_timeouts(self, run):
        run.side_effect = agent.subprocess.TimeoutExpired(["codex"], 1800)

        with self.assertRaisesRegex(RuntimeError, "timed out after 1800 seconds"):
            agent.run_agent("2+2", profile="codex")

    def test_rejects_unsupported_profiles_at_dispatch(self):
        with self.assertRaisesRegex(ValueError, "unsupported agent profile: pi"):
            agent.run_agent("2+2", profile="pi")

    @patch("agent.subprocess.run")
    @patch.dict(os.environ, {"MLFLOW_TRACKING_URI": "do-not-inherit"})
    def test_returns_the_assistant_result_without_framework_credentials(self, run):
        run.return_value = CompletedProcess(
            args=["claude"],
            returncode=0,
            stdout=json.dumps({"type": "result", "result": "4", "is_error": False}),
            stderr="",
        )

        self.assertEqual(agent.run_agent("2+2"), "4")
        self.assertNotIn("MLFLOW_TRACKING_URI", run.call_args.kwargs["env"])

    @patch("agent.subprocess.run")
    def test_surfaces_claude_api_errors(self, run):
        run.return_value = CompletedProcess(
            args=["claude"],
            returncode=1,
            stdout=json.dumps({"result": "Failed to authenticate", "is_error": True}),
            stderr="",
        )

        with self.assertRaisesRegex(RuntimeError, "Failed to authenticate"):
            agent.run_agent("2+2")

    @patch("agent.subprocess.run")
    def test_disables_tools_for_the_llm_judge(self, run):
        run.return_value = CompletedProcess(
            args=["claude"],
            returncode=0,
            stdout=json.dumps({"result": "PASS", "is_error": False}),
            stderr="",
        )

        self.assertEqual(agent.run_judge("untrusted output"), "PASS")
        command = run.call_args.args[0]
        self.assertIn("--tools", command)
        self.assertIn("--disable-slash-commands", command)


if __name__ == "__main__":
    unittest.main()
