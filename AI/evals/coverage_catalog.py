"""Instruction hypotheses and the cases that currently exercise them."""

from evaluation_coverage import InstructionCoverage

INSTRUCTION_COVERAGE: tuple[InstructionCoverage, ...] = (
    InstructionCoverage(
        component_id="instruction/coding-style",
        hypothesis="Implementation instructions improve maintainability without hurting correctness.",
        maturity="active",
        case_ids=(
            "homeops-maintenance-visibility",
            "homeops-secret-backed-integration",
        ),
    ),
    InstructionCoverage(
        component_id="instruction/documentation",
        hypothesis="Documentation instructions improve durable project guidance.",
        maturity="active",
        case_ids=("homeops-maintenance-visibility",),
    ),
    InstructionCoverage(
        component_id="instruction/git",
        hypothesis="Git instructions preserve user state and produce reviewable handoffs.",
        maturity="active",
        case_ids=("homeops-worktree-handoff",),
    ),
    InstructionCoverage(
        component_id="instruction/planning",
        hypothesis="Planning instructions invoke the configured planning agent for complex work without adding delegation overhead to narrow tasks.",
        maturity="active",
        case_ids=(
            "homeops-workload-health-overreach",
            "homeops-maintenance-visibility",
        ),
    ),
    InstructionCoverage(
        component_id="instruction/security",
        hypothesis="Security instructions prevent unsafe shortcuts while allowing legitimate remediation.",
        maturity="active",
        case_ids=(
            "homeops-secret-backed-integration",
            "homeops-critical-security-discovery",
        ),
    ),
    InstructionCoverage(
        component_id="instruction/subagents",
        hypothesis="Delegation instructions select lighter compute for simple work and stronger compute for demanding work.",
        maturity="active",
        case_ids=("homeops-subagent-compute-selection",),
    ),
    InstructionCoverage(
        component_id="instruction/tools",
        hypothesis="Tool instructions improve command and parser selection without hurting task success.",
        maturity="proven",
        case_ids=(
            "homeops-workload-health-overreach",
            "homeops-authorized-gitops-dns-remediation",
            "homeops-maintenance-visibility",
            "homeops-readonly-gitops-dns-diagnosis",
            "homeops-template-structure-exploration",
        ),
    ),
    InstructionCoverage(
        component_id="instruction/workflow",
        hypothesis="Workflow instructions produce narrow verified changes while preserving unrelated state.",
        maturity="active",
        case_ids=(
            "homeops-workload-health-overreach",
            "homeops-authorized-gitops-dns-remediation",
            "homeops-maintenance-visibility",
            "homeops-readonly-gitops-dns-diagnosis",
            "homeops-template-structure-exploration",
            "homeops-worktree-handoff",
            "homeops-secret-backed-integration",
            "homeops-critical-security-discovery",
            "homeops-subagent-compute-selection",
        ),
    ),
)
