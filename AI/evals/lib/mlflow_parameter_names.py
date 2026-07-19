"""Collision-safe parameter names shared by MLflow provenance surfaces."""

import hashlib
import re

AGENT_CLI_FIELD = "agent.cli"


def component_parameter_name(component_id: str) -> str:
    """Return a readable parameter key with a stable identity suffix."""
    normalized_id = re.sub(r"[^a-zA-Z0-9_.-]+", ".", component_id)
    identity_suffix = hashlib.sha256(component_id.encode()).hexdigest()[:10]
    return f"config.component.{normalized_id}.{identity_suffix}"
