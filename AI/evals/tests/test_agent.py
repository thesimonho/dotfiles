"""Behavior tests for normalized agent execution evidence."""

import json
import sys
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from agent import claude_result_from_output, codex_result_from_output  # noqa: E402


class CodexResultTest(unittest.TestCase):
    def test_extracts_final_response_and_shell_commands(self) -> None:
        events = (
            {
                "type": "item.completed",
                "item": {
                    "type": "command_execution",
                    "command": (
                        "/home/simon/.nix-profile/bin/zsh -lc "
                        "\"rtk jq '.deployments[]' inventory.json\""
                    ),
                },
            },
            {
                "type": "item.completed",
                "item": {
                    "type": "agent_message",
                    "text": "Region: ca-west-1",
                },
            },
        )
        output = "\n".join(json.dumps(event) for event in events)

        result = codex_result_from_output(output)

        self.assertEqual(result.response, "Region: ca-west-1")
        self.assertEqual(
            result.shell_commands,
            ("rtk jq '.deployments[]' inventory.json",),
        )


class ClaudeResultTest(unittest.TestCase):
    def test_extracts_bash_tool_use_from_stream_json(self) -> None:
        events = (
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "Bash",
                            "input": {
                                "command": "rtk jq '.deployments[]' inventory.json"
                            },
                        }
                    ]
                },
            },
            {"type": "result", "is_error": False, "result": "Region: ca-west-1"},
        )
        output = "\n".join(json.dumps(event) for event in events)

        result = claude_result_from_output(output)

        self.assertEqual(result.response, "Region: ca-west-1")
        self.assertEqual(
            result.shell_commands,
            ("rtk jq '.deployments[]' inventory.json",),
        )


if __name__ == "__main__":
    unittest.main()
