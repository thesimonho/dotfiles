"""Typed contracts for git-tracked agent evaluation cases."""

from typing import Literal, TypedDict


class CommonEvaluationCase(TypedDict):
    """Fields shared by every evaluation case and MLflow surface."""

    case_id: str
    category: str
    metric_name: str
    prompt: str


class OutputQualityCase(CommonEvaluationCase):
    """A case judged against a natural-language quality rubric."""

    tier: Literal["output-quality"]
    rubric: str


class OutputContainsCase(CommonEvaluationCase):
    """A deterministic case requiring text in the final response."""

    tier: Literal["output-contains"]
    expected_mention: str


type EvaluationCase = OutputQualityCase | OutputContainsCase
