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
    evaluation_execution_id: str
    config_manifest_id: str
    comparison_group_id: str | None = None
    comparison_variant: str | None = None
    ablated_component_id: str | None = None

    def otel_resource_attributes(self) -> str:
        """Serialize safe resource attributes for the OTEL SDK environment."""
        attributes = {
            "telemetry.purpose": "evaluation",
            "agent.cli": self.agent_cli,
            "case_id": self.case_id,
            "category": self.category,
            "evaluation.role": self.evaluation_role,
            "evaluation.execution_id": self.evaluation_execution_id,
            "config.manifest_id": self.config_manifest_id,
        }
        optional_attributes = {
            "evaluation.comparison_group_id": self.comparison_group_id,
            "evaluation.variant": self.comparison_variant,
            "evaluation.ablated_component_id": self.ablated_component_id,
        }
        attributes.update(
            {
                name: value
                for name, value in optional_attributes.items()
                if value is not None
            }
        )
        return ",".join(
            f"{name}={quote(value, safe='-._~/')}" for name, value in attributes.items()
        )
