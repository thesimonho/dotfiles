"""Behavior tests for MLflow evaluation dataset records."""

import sys
import unittest
from pathlib import Path
from typing import cast

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from dataset_sync import _prepare_empty_dataset, mlflow_records  # noqa: E402
from evaluation_case import EvaluationCase  # noqa: E402


class EmptyMlflowDataset:
    """Reproduce MLflow 3.14's loaded-empty record cache."""

    def __init__(self) -> None:
        self._records = []

    @property
    def records(self) -> list:
        return self._records


class DatasetWrapper:
    def __init__(self) -> None:
        self._mlflow_dataset = EmptyMlflowDataset()


class MlflowRecordsTest(unittest.TestCase):
    """Keep reusable metric declarations intact in hosted dataset rows."""

    def test_stores_all_metrics_as_expectations(self) -> None:
        metrics = (
            {
                "name": "answer_correct",
                "evaluator": "output-contains",
                "expected_mention": "ca-west-1",
            },
            {
                "name": "shell_command_count",
                "evaluator": "shell-command-count",
            },
        )
        cases = cast(
            tuple[EvaluationCase, ...],
            (
                {
                    "case_id": "tools-json-lookup",
                    "category": "instruction-tools",
                    "prompt": "Inspect the inventory.",
                    "workspace": {
                        "environment": "homeops",
                        "scenario": "rollout-dns-failure",
                        "access": "read-only",
                    },
                    "metrics": metrics,
                },
            ),
        )

        records = mlflow_records(cases)

        self.assertEqual(records[0]["expectations"], {"metrics": metrics})
        self.assertEqual(
            records[0]["inputs"]["workspace"],
            {
                "environment": "homeops",
                "scenario": "rollout-dns-failure",
                "access": "read-only",
            },
        )

    def test_clears_mlflow_loaded_empty_cache_before_first_merge(self) -> None:
        dataset = DatasetWrapper()

        _prepare_empty_dataset(dataset)

        self.assertIsNone(dataset._mlflow_dataset._records)


if __name__ == "__main__":
    unittest.main()
