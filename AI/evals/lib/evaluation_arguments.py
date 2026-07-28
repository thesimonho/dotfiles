"""Command-line arguments for MLflow evaluation runs."""

import argparse

from cases import EVALUATION_SUITES
from harness_environment import AGENT_ARGUMENT_CHOICES


def parse_evaluation_arguments() -> argparse.Namespace:
    """Parse agent compute, case selection, and comparison arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--agent",
        choices=AGENT_ARGUMENT_CHOICES,
        default="auto",
        help="Agent CLI and configuration profile to evaluate.",
    )
    parser.add_argument(
        "--model",
        help="Exact model or CLI-supported model alias to evaluate.",
    )
    parser.add_argument(
        "--effort",
        help="CLI-supported reasoning or effort level to evaluate.",
    )
    parser.add_argument(
        "--baseline-manifest-version",
        type=int,
        help="Compare against this MLflow manifest prompt version instead of the latest.",
    )
    selection_group = parser.add_mutually_exclusive_group()
    selection_group.add_argument(
        "--case-id",
        action="append",
        dest="case_ids",
        help="Evaluate only this case ID without replacing the complete hosted dataset.",
    )
    selection_group.add_argument(
        "--suite",
        choices=tuple(EVALUATION_SUITES),
        help="Evaluate a named cost tier from the case catalog.",
    )
    parser.add_argument(
        "--compare-component",
        help=(
            "Run treatment and control arms, removing exactly this instruction "
            "component from the control configuration."
        ),
    )
    return parser.parse_args()
