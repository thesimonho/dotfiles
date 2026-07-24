"""Universal timing, token, and parser-coverage feedback for eval cases."""

from typing import Any

from mlflow.entities import Feedback


def operational_feedback(
    operational_evidence: dict[str, Any],
    execution_evidence: dict[str, Any],
) -> list[Feedback]:
    """Expose diagnostics without assigning pass/fail thresholds."""
    feedback = [
        Feedback(
            name="case_completion_seconds",
            value=float(operational_evidence["case_completion_seconds"]),
            rationale="Harness-measured predictor wall-clock duration in seconds.",
        ),
        Feedback(
            name="agent_invocation_seconds",
            value=float(operational_evidence["agent_invocation_seconds"]),
            rationale="Harness-measured authenticated CLI subprocess duration in seconds.",
        ),
        Feedback(
            name="evidence_contract_satisfied",
            value=not execution_evidence["unobserved_required_evidence"],
            rationale=(
                "All must-observe evidence requirements were present."
                if not execution_evidence["unobserved_required_evidence"]
                else "Missing must-observe evidence: "
                + ", ".join(execution_evidence["unobserved_required_evidence"])
            ),
        ),
        Feedback(
            name="unknown_agent_event_type_count",
            value=float(
                len(execution_evidence["event_coverage"]["unknown_event_types"])
            ),
            rationale=(
                "Distinct CLI event shapes without an explicit parser "
                "classification; diagnostic only."
            ),
        ),
    ]
    feedback.extend(_token_feedback(operational_evidence["token_usage"]))
    return feedback


def _token_feedback(token_usage: dict[str, Any]) -> list[Feedback]:
    """Return every token dimension emitted or deterministically derived."""
    token_metric_names = {
        "input_tokens": "input_token_count",
        "uncached_input_tokens": "uncached_input_token_count",
        "cached_input_tokens": "cached_input_token_count",
        "cache_creation_input_tokens": "cache_creation_input_token_count",
        "output_tokens": "output_token_count",
        "reasoning_output_tokens": "reasoning_output_token_count",
        "total_tokens": "total_token_count",
    }
    return [
        Feedback(
            name=metric_name,
            value=float(token_usage[token_name]),
            rationale=(
                f"Token usage reported or derived from {token_usage['source']}; "
                "diagnostic only."
            ),
        )
        for token_name, metric_name in token_metric_names.items()
        if isinstance(token_usage.get(token_name), int)
    ]
