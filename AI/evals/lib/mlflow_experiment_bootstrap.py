"""Create the shared MLflow experiment and render Alloy's runtime identity."""

import os
import tempfile

from harness_environment import REPOSITORY_ROOT
from harness_identity import MLFLOW_EXPERIMENT_NAME, MLFLOW_TRACKING_URI
from mlflow.tracking import MlflowClient

RUNTIME_ENVIRONMENT_PATH = REPOSITORY_ROOT / "infra/compose/.env.mlflow-runtime"


def bootstrap_experiment() -> str:
    """Create or reuse the harness experiment and return its stable ID."""
    client = MlflowClient(tracking_uri=MLFLOW_TRACKING_URI)
    experiment = client.get_experiment_by_name(MLFLOW_EXPERIMENT_NAME)
    if experiment is not None:
        return experiment.experiment_id
    return client.create_experiment(MLFLOW_EXPERIMENT_NAME)


def write_runtime_environment(experiment_id: str) -> None:
    """Atomically write the ignored environment file consumed by Alloy."""
    RUNTIME_ENVIRONMENT_PATH.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_path = tempfile.mkstemp(
        dir=RUNTIME_ENVIRONMENT_PATH.parent,
        prefix=".env.mlflow-runtime.",
    )
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as environment_file:
            environment_file.write(f"MLFLOW_EXPERIMENT_ID={experiment_id}\n")
        os.chmod(temporary_path, 0o600)
        os.replace(temporary_path, RUNTIME_ENVIRONMENT_PATH)
    finally:
        if os.path.exists(temporary_path):
            os.unlink(temporary_path)


if __name__ == "__main__":
    write_runtime_environment(bootstrap_experiment())
