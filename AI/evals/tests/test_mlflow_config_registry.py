"""Behavior tests for configuration baseline lookup."""

import sys
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from mlflow_config_registry import MlflowConfigurationRegistry  # noqa: E402


class AliasMissingError(Exception):
    """Match MLflow's error shape when a prompt exists without the alias."""

    error_code = "INVALID_PARAMETER_VALUE"


class ClientWithoutBaselineAlias:
    """Expose the failure returned after an interrupted first evaluation."""

    def get_prompt_version_by_alias(self, name: str, alias: str):
        raise AliasMissingError(f"Prompt alias {alias} not found")


class BaselineManifestPromptTest(unittest.TestCase):
    def test_missing_last_evaluated_alias_means_no_baseline(self) -> None:
        registry = MlflowConfigurationRegistry(
            ClientWithoutBaselineAlias(),
            genai=None,
            profile="codex",
        )

        baseline = registry._baseline_manifest_prompt(None)

        self.assertIsNone(baseline)


if __name__ == "__main__":
    unittest.main()
