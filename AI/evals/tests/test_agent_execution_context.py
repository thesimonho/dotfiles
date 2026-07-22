"""Behavior tests for cross-system evaluation identity serialization."""

import sys
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from agent_execution_context import AgentExecutionContext  # noqa: E402


class AgentExecutionContextTest(unittest.TestCase):
    """Keep filter values identical across OTEL traces and MLflow runs."""

    def test_preserves_component_id_path_separator(self) -> None:
        context = AgentExecutionContext(
            agent_cli="codex",
            case_id="case-one",
            category="instruction-tools",
            evaluation_role="agent-under-test",
            evaluation_execution_id="execution-one",
            config_manifest_id="manifest-one",
            comparison_group_id="comparison-one",
            comparison_variant="control",
            ablated_component_id="instruction/tools",
        )

        attributes = context.otel_resource_attributes()

        self.assertIn(
            "evaluation.ablated_component_id=instruction/tools",
            attributes,
        )
        self.assertNotIn("instruction%2Ftools", attributes)


if __name__ == "__main__":
    unittest.main()
