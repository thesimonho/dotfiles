"""Shared names that define agent-harness resources and ownership."""

MLFLOW_TRACKING_URI = "http://localhost:5000"
MLFLOW_EXPERIMENT_NAME = "agent-harness-evals"
EVALUATION_DATASET_NAME = "agent-harness-cases"
PROMPT_NAMESPACE_PREFIX = "agent-harness--"


def manifest_prompt_name(profile: str) -> str:
    """Return the profile-specific manifest name in the owned namespace."""
    return f"{PROMPT_NAMESPACE_PREFIX}{profile}--manifest"
