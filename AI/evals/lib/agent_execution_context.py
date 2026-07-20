"""Immutable OpenTelemetry identity for one evaluation CLI invocation."""

from dataclasses import dataclass
from typing import Literal
from urllib.parse import quote

EvaluationRole = Literal["agent-under-test", "judge"]


@dataclass(frozen=True)
class AgentExecutionContext:
    """Describe one agent process without including prompt or response content."""

    agent_cli: str
    case_id: str
    category: str
    evaluation_role: EvaluationRole

    def otel_resource_attributes(self) -> str:
        """Serialize safe resource attributes for the OTEL SDK environment."""
        attributes = {
            "telemetry.purpose": "evaluation",
            "agent.cli": self.agent_cli,
            "case_id": self.case_id,
            "category": self.category,
            "evaluation.role": self.evaluation_role,
        }
        return ",".join(
            f"{name}={quote(value, safe='-._~')}" for name, value in attributes.items()
        )
