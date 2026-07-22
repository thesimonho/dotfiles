"""Instruction hypotheses and the cases that currently exercise them."""

from evaluation_coverage import InstructionCoverage

INSTRUCTION_COVERAGE: tuple[InstructionCoverage, ...] = (
    InstructionCoverage(
        component_id="instruction/coding-style",
        hypothesis="Implementation instructions improve maintainability without hurting correctness.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/documentation",
        hypothesis="Documentation instructions improve durable project guidance.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/git",
        hypothesis="Git instructions preserve user state and produce reviewable handoffs.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/images",
        hypothesis="Image instructions preserve generated assets and verification evidence appropriately.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/planning",
        hypothesis="Planning instructions reduce avoidable rework on genuinely complex tasks.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/security",
        hypothesis="Security instructions prevent unsafe shortcuts while allowing legitimate remediation.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/subagents",
        hypothesis="Delegation instructions improve suitable work without adding overhead to simple tasks.",
        maturity="planned",
        case_ids=(),
    ),
    InstructionCoverage(
        component_id="instruction/tools",
        hypothesis="Tool instructions improve command and parser selection without hurting task success.",
        maturity="proven",
        case_ids=(
            "tools-json-production-deployment",
            "homeops-workload-health-regression",
        ),
    ),
    InstructionCoverage(
        component_id="instruction/workflow",
        hypothesis="Workflow instructions produce narrow verified changes while preserving unrelated state.",
        maturity="active",
        case_ids=("homeops-workload-health-overreach",),
    ),
)
