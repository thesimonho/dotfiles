"""Shared MLflow setup for eval scores and traces in one experiment."""

import mlflow
import mlflow.genai
from harness_identity import MLFLOW_EXPERIMENT_NAME, MLFLOW_TRACKING_URI
from mlflow.environment_variables import (
    MLFLOW_HTTP_REQUEST_BACKOFF_FACTOR,
    MLFLOW_HTTP_REQUEST_MAX_RETRIES,
    MLFLOW_HTTP_REQUEST_TIMEOUT,
)

EXPERIMENT_NAME = MLFLOW_EXPERIMENT_NAME

# MLflow defaults to seven retries against a 120 second timeout with
# exponential backoff, so one unreachable tracking server can hold a
# request for roughly twenty minutes. The suite waits for MLflow to answer
# before it starts and talks to it over the loopback interface, so a long
# retry budget buys nothing and hides a wedged server behind what looks
# exactly like a slow run. Keep enough tolerance for a restarting
# container and surface anything worse within a couple of minutes.
_REQUEST_TIMEOUT_SECONDS = 30
_REQUEST_MAX_RETRIES = 3

_initialized = False


def init():
    """Initialize MLflow tracing without deriving agent identity from Git."""
    global _initialized
    if not _initialized:
        MLFLOW_HTTP_REQUEST_TIMEOUT.set(_REQUEST_TIMEOUT_SECONDS)
        MLFLOW_HTTP_REQUEST_MAX_RETRIES.set(_REQUEST_MAX_RETRIES)
        MLFLOW_HTTP_REQUEST_BACKOFF_FACTOR.set(2)
        mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
        mlflow.set_experiment(EXPERIMENT_NAME)
        _initialized = True
