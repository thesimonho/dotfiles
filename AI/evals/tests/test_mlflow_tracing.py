"""Behavior tests for MLflow harness initialization."""

import sys
import unittest
from pathlib import Path
from unittest.mock import patch

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

import mlflow_tracing  # noqa: E402


class MlflowTracingTests(unittest.TestCase):
    """Verify tracing setup does not infer configuration identity from Git."""

    def test_initializes_the_experiment_without_git_model_versioning(self):
        mlflow_tracing._initialized = False

        with (
            patch.object(mlflow_tracing.mlflow, "set_tracking_uri"),
            patch.object(mlflow_tracing.mlflow, "set_experiment"),
            patch.object(
                mlflow_tracing.mlflow.genai,
                "enable_git_model_versioning",
            ) as enable_git_model_versioning,
        ):
            result = mlflow_tracing.init()

        self.assertIsNone(result)
        enable_git_model_versioning.assert_not_called()


if __name__ == "__main__":
    unittest.main()
