"""Shared MLflow setup for eval scores and traces in one experiment."""

import mlflow
import mlflow.genai
from harness_identity import MLFLOW_EXPERIMENT_NAME, MLFLOW_TRACKING_URI

EXPERIMENT_NAME = MLFLOW_EXPERIMENT_NAME

_initialized = False


def init():
    """Initialize MLflow tracing without deriving agent identity from Git."""
    global _initialized
    if not _initialized:
        mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
        mlflow.set_experiment(EXPERIMENT_NAME)
        _initialized = True
