"""Preview instruction comparison usage without invoking an agent or MLflow."""

import argparse
import sys
from pathlib import Path

EVALUATION_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(EVALUATION_ROOT / "lib"))
sys.path.insert(0, str(EVALUATION_ROOT))

from cases import CASES  # noqa: E402
from agent_event_contract import validate_case_evidence_requirements  # noqa: E402
from coverage_catalog import INSTRUCTION_COVERAGE  # noqa: E402
from evaluation_coverage import (  # noqa: E402
    format_campaign_plan,
    plan_instruction_campaign,
)


def parse_arguments() -> argparse.Namespace:
    """Parse a zero-execution campaign preview request."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--agent", choices=("codex", "claude"), required=True)
    parser.add_argument("--component", required=True)
    parser.add_argument("--repetitions", type=int, default=1)
    return parser.parse_args()


def main() -> None:
    """Print the projected usage boundary without external side effects."""
    arguments = parse_arguments()
    plan = plan_instruction_campaign(
        arguments.component,
        repetitions=arguments.repetitions,
        coverage=INSTRUCTION_COVERAGE,
        cases=CASES,
    )
    planned_case_ids = set(plan.case_ids)
    planned_cases = tuple(case for case in CASES if case["case_id"] in planned_case_ids)
    validate_case_evidence_requirements(arguments.agent, planned_cases)
    print(format_campaign_plan(plan, agent_profile=arguments.agent))


if __name__ == "__main__":
    main()
