"""Reset expendable agent-harness history on the local MLflow server."""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))

import mlflow  # noqa: E402
from mlflow import MlflowClient  # noqa: E402
from harness_identity import MLFLOW_TRACKING_URI  # noqa: E402
from mlflow_harness_reset import reset_local_harness  # noqa: E402


def parse_arguments() -> argparse.Namespace:
    """Require an explicit acknowledgement for destructive cleanup."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Delete the local eval harness's runs, traces, models, dataset, and prompts.",
    )
    arguments = parser.parse_args()
    if not arguments.yes:
        parser.error("pass --yes to confirm deletion of expendable harness history")
    return arguments


if __name__ == "__main__":
    parse_arguments()
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    reset_report = reset_local_harness(MlflowClient())
    print(f"deleted traces: {len(reset_report.deleted_trace_ids)}")
    print(f"deleted runs: {len(reset_report.deleted_run_ids)}")
    print(f"deleted agent versions: {len(reset_report.deleted_model_ids)}")
    print(f"deleted datasets: {len(reset_report.deleted_dataset_ids)}")
    print(f"deleted prompts: {len(reset_report.deleted_prompt_names)}")
