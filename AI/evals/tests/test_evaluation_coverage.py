"""Behavior tests for cost-aware instruction coverage planning."""

import sys
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))
sys.path.insert(0, str(EVAL_ROOT))

from cases import CASES  # noqa: E402
from coverage_catalog import INSTRUCTION_COVERAGE  # noqa: E402
from evaluation_case import EvaluationCase  # noqa: E402
from evaluation_coverage import (  # noqa: E402
    InstructionCoverage,
    format_campaign_plan,
    plan_instruction_campaign,
    validate_coverage_catalog,
)


class EvaluationCoverageTest(unittest.TestCase):
    """Keep coverage references aligned with the executable case suite."""

    def test_rejects_unknown_case_references(self) -> None:
        coverage = (
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="Narrow changes preserve unrelated state.",
                maturity="active",
                case_ids=("missing-case",),
            ),
        )

        with self.assertRaisesRegex(ValueError, "missing-case"):
            validate_coverage_catalog(coverage, known_case_ids=("known-case",))

    def test_rejects_duplicate_component_entries(self) -> None:
        coverage = (
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="First hypothesis.",
                maturity="active",
                case_ids=("known-case",),
            ),
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="Conflicting hypothesis.",
                maturity="active",
                case_ids=("known-case",),
            ),
        )

        with self.assertRaisesRegex(ValueError, "instruction/workflow"):
            validate_coverage_catalog(coverage, known_case_ids=("known-case",))

    def test_requires_cases_for_active_coverage(self) -> None:
        coverage = (
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="Narrow changes preserve unrelated state.",
                maturity="active",
                case_ids=(),
            ),
        )

        with self.assertRaisesRegex(ValueError, "active.*instruction/workflow"):
            validate_coverage_catalog(coverage, known_case_ids=("known-case",))

    def test_rejects_duplicate_cases_within_one_component(self) -> None:
        coverage = (
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="Narrow changes preserve unrelated state.",
                maturity="active",
                case_ids=("known-case", "known-case"),
            ),
        )

        with self.assertRaisesRegex(ValueError, "known-case"):
            validate_coverage_catalog(coverage, known_case_ids=("known-case",))

    def test_plans_paired_agent_usage_before_execution(self) -> None:
        cases: tuple[EvaluationCase, ...] = (
            {
                "case_id": "workflow-narrow-fix",
                "category": "instruction-minimal-change",
                "prompt": "Make the narrow fix.",
                "metrics": (),
            },
            {
                "case_id": "workflow-overreach",
                "category": "instruction-minimal-change",
                "prompt": "Avoid tempting unrelated cleanup.",
                "metrics": (),
            },
        )
        coverage = (
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="Narrow changes preserve unrelated state.",
                maturity="active",
                case_ids=("workflow-narrow-fix", "workflow-overreach"),
            ),
        )

        plan = plan_instruction_campaign(
            "instruction/workflow",
            repetitions=1,
            coverage=coverage,
            cases=cases,
        )

        self.assertEqual(
            plan.case_ids,
            ("workflow-narrow-fix", "workflow-overreach"),
        )
        self.assertEqual(plan.comparison_pairs, 2)
        self.assertEqual(plan.agent_under_test_invocations, 4)
        self.assertEqual(plan.judge_invocations, 0)
        self.assertEqual(plan.total_cli_invocations, 4)

    def test_includes_judge_calls_in_projected_usage(self) -> None:
        cases: tuple[EvaluationCase, ...] = (
            {
                "case_id": "judged-case",
                "category": "instruction-documentation",
                "prompt": "Improve the documentation.",
                "metrics": (
                    {
                        "name": "documentation_quality",
                        "evaluator": "output-quality",
                        "rubric": "The result is clear and accurate.",
                    },
                ),
            },
        )
        coverage = (
            InstructionCoverage(
                component_id="instruction/documentation",
                hypothesis="Documentation instructions improve clarity.",
                maturity="planned",
                case_ids=("judged-case",),
            ),
        )

        plan = plan_instruction_campaign(
            "instruction/documentation",
            repetitions=2,
            coverage=coverage,
            cases=cases,
        )

        self.assertEqual(plan.agent_under_test_invocations, 4)
        self.assertEqual(plan.judge_invocations, 4)
        self.assertEqual(plan.total_cli_invocations, 8)

    def test_formats_usage_before_any_agent_is_invoked(self) -> None:
        coverage = (
            InstructionCoverage(
                component_id="instruction/workflow",
                hypothesis="Narrow changes preserve unrelated state.",
                maturity="active",
                case_ids=("workflow-case",),
            ),
        )
        cases: tuple[EvaluationCase, ...] = (
            {
                "case_id": "workflow-case",
                "category": "instruction-minimal-change",
                "prompt": "Make the narrow fix.",
                "metrics": (),
            },
        )
        plan = plan_instruction_campaign(
            "instruction/workflow",
            repetitions=1,
            coverage=coverage,
            cases=cases,
        )

        output = format_campaign_plan(plan, agent_profile="codex")

        self.assertIn("agent profile: codex", output)
        self.assertIn("comparison pairs: 1", output)
        self.assertIn("agent-under-test invocations: 2", output)
        self.assertIn("judge invocations: 0", output)
        self.assertIn("total CLI invocations: 2", output)
        self.assertIn("workflow-case", output)

    def test_real_workflow_campaign_is_bounded_to_two_agent_invocations(
        self,
    ) -> None:
        plan = plan_instruction_campaign(
            "instruction/workflow",
            repetitions=1,
            coverage=INSTRUCTION_COVERAGE,
            cases=CASES,
        )

        self.assertEqual(len(CASES), 5)
        self.assertEqual(plan.comparison_pairs, 1)
        self.assertEqual(plan.agent_under_test_invocations, 2)
        self.assertEqual(plan.total_cli_invocations, 2)

    def test_real_catalog_covers_every_instruction_fragment(self) -> None:
        fragment_root = EVAL_ROOT.parent / "instructions" / "fragments"
        fragment_component_ids = {
            f"instruction/{path.stem}" for path in fragment_root.glob("*.md")
        }
        catalog_component_ids = {entry.component_id for entry in INSTRUCTION_COVERAGE}

        self.assertEqual(catalog_component_ids, fragment_component_ids)


if __name__ == "__main__":
    unittest.main()
