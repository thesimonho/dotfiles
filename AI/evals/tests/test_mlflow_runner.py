"""Behavior tests for the MLflow evaluation runner."""

import sys
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import call, patch

EVAL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_DIR))

import run_mlflow_eval  # noqa: E402


class MlflowRunnerTests(unittest.TestCase):
    """Verify trace-list previews remain readable."""

    def test_rejects_an_empty_suite_before_initializing_mlflow(self):
        arguments = Namespace(agent="codex", baseline_manifest_version=None)
        with (
            patch.object(run_mlflow_eval, "CASES", ()),
            patch.object(run_mlflow_eval.mlflow_tracing, "init") as initialize,
        ):
            with self.assertRaisesRegex(RuntimeError, "no evaluation cases configured"):
                run_mlflow_eval.run_evaluation(arguments)

        initialize.assert_not_called()

    def test_sets_plain_request_and_response_trace_previews(self):
        with (
            patch.object(
                run_mlflow_eval.agent,
                "run_agent",
                return_value="plain answer",
            ),
            patch.object(
                run_mlflow_eval.mlflow,
                "update_current_trace",
            ) as update_current_trace,
            patch.object(
                run_mlflow_eval.mlflow,
                "get_current_active_span",
                return_value=object(),
            ),
            patch.object(run_mlflow_eval, "AGENT_PROFILE", "codex"),
        ):
            response = run_mlflow_eval.predict_fn(
                "plain prompt",
                case_id="plain-response",
                category="response-quality",
            )

        self.assertEqual(response, "plain answer")
        self.assertEqual(
            update_current_trace.call_args_list,
            [
                call(
                    metadata={
                        "agent.cli": "codex",
                        "case_id": "plain-response",
                        "category": "response-quality",
                    },
                    request_preview="plain prompt",
                ),
                call(response_preview="plain answer"),
            ],
        )

    def test_skips_previews_during_mlflow_untraced_input_validation(self):
        with (
            patch.object(
                run_mlflow_eval.agent,
                "run_agent",
                return_value="plain answer",
            ),
            patch.object(
                run_mlflow_eval.mlflow,
                "update_current_trace",
            ) as update_current_trace,
            patch.object(
                run_mlflow_eval.mlflow,
                "get_current_active_span",
                return_value=None,
            ),
        ):
            run_mlflow_eval.predict_fn(
                "plain prompt",
                case_id="plain-response",
                category="response-quality",
            )

        update_current_trace.assert_not_called()


if __name__ == "__main__":
    unittest.main()
