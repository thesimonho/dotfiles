"""Behavior tests for inspectable paired evaluation evidence."""

import sys
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from comparison_evidence import (  # noqa: E402
    ComparisonArmResult,
    build_comparison_evidence,
)


class ComparisonEvidenceTest(unittest.TestCase):
    """Compare arms only when their task inputs are identical."""

    def test_reports_raw_deltas_and_directional_improvements(self) -> None:
        treatment = ComparisonArmResult(
            variant="treatment",
            run_id="run-treatment",
            manifest_id="manifest-treatment",
            metrics={
                "shell_command_prefix_rate/mean": 0.75,
                "unnecessary_change_count/mean": 0.0,
                "shell_command_count/mean": 12.0,
            },
            workspace_snapshot_hashes={"case-one": "same-snapshot"},
        )
        control = ComparisonArmResult(
            variant="control",
            run_id="run-control",
            manifest_id="manifest-control",
            metrics={
                "shell_command_prefix_rate/mean": 0.25,
                "unnecessary_change_count/mean": 2.0,
                "shell_command_count/mean": 8.0,
            },
            workspace_snapshot_hashes={"case-one": "same-snapshot"},
        )

        evidence = build_comparison_evidence(
            comparison_group_id="comparison-one",
            ablated_component_id="instruction/tools",
            treatment=treatment,
            control=control,
        )

        self.assertEqual(
            evidence["metric_deltas"]["shell_command_prefix_rate/mean"],
            {
                "control": 0.25,
                "treatment": 0.75,
                "treatment_minus_control": 0.5,
                "improvement": 0.5,
                "direction": "higher-is-better",
            },
        )
        self.assertEqual(
            evidence["metric_deltas"]["unnecessary_change_count/mean"]["improvement"],
            2.0,
        )
        self.assertIsNone(
            evidence["metric_deltas"]["shell_command_count/mean"]["improvement"]
        )

    def test_rejects_different_workspace_snapshots(self) -> None:
        treatment = ComparisonArmResult(
            variant="treatment",
            run_id="run-treatment",
            manifest_id="manifest-treatment",
            metrics={},
            workspace_snapshot_hashes={"case-one": "first-snapshot"},
        )
        control = ComparisonArmResult(
            variant="control",
            run_id="run-control",
            manifest_id="manifest-control",
            metrics={},
            workspace_snapshot_hashes={"case-one": "second-snapshot"},
        )

        with self.assertRaisesRegex(ValueError, "different workspace snapshots"):
            build_comparison_evidence(
                comparison_group_id="comparison-one",
                ablated_component_id="instruction/tools",
                treatment=treatment,
                control=control,
            )


if __name__ == "__main__":
    unittest.main()
