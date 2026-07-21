"""Behavior tests for reusable evaluation metrics."""

import sys
import unittest
from pathlib import Path
from typing import cast

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from scoring import score_execution_metrics, score_response_metrics  # noqa: E402
from evaluation_case import EvaluationMetric  # noqa: E402


class ScoreResponseMetricsTest(unittest.TestCase):
    """Score every response metric declared by one evaluation case."""

    def test_scores_multiple_metrics_without_emitting_execution_metrics(self) -> None:
        metrics = cast(
            tuple[EvaluationMetric, ...],
            (
                {
                    "name": "answer_correct",
                    "evaluator": "output-contains-all",
                    "expected_mentions": (
                        "ca-west-1",
                        "payments-api-20260718-03",
                    ),
                },
                {
                    "name": "all_shell_commands_prefixed",
                    "evaluator": "all-shell-commands-prefixed",
                    "prefix": "rtk",
                },
            ),
        )

        results = score_response_metrics(
            "Region: ca-west-1\nDeployment: payments-api-20260718-03",
            metrics,
            context=None,
        )

        self.assertEqual(
            [(result.name, result.value) for result in results],
            [
                ("answer_correct", True),
            ],
        )

    def test_scores_reusable_shell_command_metrics(self) -> None:
        metrics = cast(
            tuple[EvaluationMetric, ...],
            (
                {
                    "name": "used_structured_parser",
                    "evaluator": "used-command",
                    "command": "jq",
                },
                {
                    "name": "all_shell_commands_prefixed",
                    "evaluator": "all-shell-commands-prefixed",
                    "prefix": "rtk",
                },
                {
                    "name": "shell_command_count",
                    "evaluator": "shell-command-count",
                },
            ),
        )

        results = score_execution_metrics(
            ("rtk jq '.deployments[]' inventory.json",),
            metrics,
        )

        self.assertEqual(
            [(result.name, result.value) for result in results],
            [
                ("used_structured_parser", True),
                ("all_shell_commands_prefixed", True),
                ("shell_command_count", 1),
            ],
        )

    def test_scores_compound_commands_by_executable_position(self) -> None:
        metrics = cast(
            tuple[EvaluationMetric, ...],
            (
                {
                    "name": "used_structured_parser",
                    "evaluator": "used-command",
                    "command": "jq",
                },
                {
                    "name": "all_shell_commands_prefixed",
                    "evaluator": "all-shell-commands-prefixed",
                    "prefix": "rtk",
                },
            ),
        )

        results = score_execution_metrics(
            (
                "rtk grep jq README.md",
                "rtk jq . first.json && jq . second.json",
            ),
            metrics,
        )

        self.assertEqual(
            [(result.name, result.value) for result in results],
            [
                ("used_structured_parser", True),
                ("all_shell_commands_prefixed", False),
            ],
        )

    def test_finds_commands_invoked_by_a_shell_wrapper(self) -> None:
        metrics = cast(
            tuple[EvaluationMetric, ...],
            (
                {
                    "name": "used_structured_parser",
                    "evaluator": "used-command",
                    "command": "jq",
                },
            ),
        )

        results = score_execution_metrics(
            ('rtk sh -c "jq . inventory.json"',),
            metrics,
        )

        self.assertEqual(results[0].value, True)


if __name__ == "__main__":
    unittest.main()
