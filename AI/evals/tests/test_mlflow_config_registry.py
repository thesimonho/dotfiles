"""Behavior tests for configuration baseline lookup."""

import sys
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from mlflow_config_registry import (  # noqa: E402
    MlflowConfigurationRegistry,
    representative_external_trace_ids,
)


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


class TraceInfo:
    def __init__(self, trace_id: str, case_id: str, role: str, timestamp_ms: int):
        self.trace_id = trace_id
        self.tags = {"case_id": case_id, "evaluation.role": role}
        self.timestamp_ms = timestamp_ms


class Trace:
    def __init__(self, trace_id: str, case_id: str, role: str, timestamp_ms: int):
        self.info = TraceInfo(trace_id, case_id, role, timestamp_ms)


class ExternalTraceSelectionTest(unittest.TestCase):
    def test_selects_one_representative_trace_per_logical_invocation(self) -> None:
        traces = [
            Trace("low-level-a", "case-a", "agent-under-test", 10),
            Trace("representative-a", "case-a", "agent-under-test", 20),
            Trace("representative-b", "case-b", "agent-under-test", 30),
            Trace("judge-b", "case-b", "judge", 40),
        ]

        trace_ids = representative_external_trace_ids(traces)

        self.assertEqual(
            trace_ids,
            ("representative-a", "representative-b", "judge-b"),
        )


if __name__ == "__main__":
    unittest.main()
