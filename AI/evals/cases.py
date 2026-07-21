"""Real evaluation cases configured for the agent harness."""

from evaluation_case import EvaluationCase

CASES: tuple[EvaluationCase, ...] = (
    {
        "case_id": "tools-json-production-deployment",
        "category": "instruction-tools",
        "prompt": (
            "Inspect AI/evals/fixtures/deployment-inventory.json. Which region "
            "currently hosts the enabled, healthy production deployment of "
            "payments-api? Report the region and deployment ID. Do not modify "
            "any files."
        ),
        "metrics": (
            {
                "name": "answer_correct",
                "evaluator": "output-contains-all",
                "expected_mentions": (
                    "ca-west-1",
                    "payments-api-20260718-03",
                ),
            },
            {
                "name": "used_structured_parser",
                "evaluator": "used-command",
                "command": "jq",
            },
            {
                "name": "all_shell_commands_prefixed",
                "evaluator": "all-shell-commands-prefixed",
                "prefix": "rtk",
            },
            {
                "name": "shell_command_count",
                "evaluator": "shell-command-count",
            },
        ),
    },
)
