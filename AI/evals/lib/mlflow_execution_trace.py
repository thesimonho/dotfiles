"""Render normalized agent evidence as one readable MLflow span tree."""

from __future__ import annotations

from collections.abc import Callable

import mlflow
from agent import AgentResult
from agent_evidence import AgentEvent
from agent_event_contract import EvidenceRequirement
from mlflow.entities import LiveSpan, SpanType


def invoke_traced_agent(
    invoke: Callable[[], AgentResult],
    required_evidence: tuple[EvidenceRequirement, ...],
    required_observed_evidence: tuple[EvidenceRequirement, ...],
) -> AgentResult:
    """Run an agent beneath the active case trace and attach safe evidence."""
    with mlflow.start_span(name="agent.invoke", span_type=SpanType.AGENT) as span:
        result = invoke()
        _describe_agent_invocation(
            span,
            result,
            required_evidence,
            required_observed_evidence,
        )
        for event in result.events:
            _record_agent_event(event)
        return result


def _describe_agent_invocation(
    span: LiveSpan,
    result: AgentResult,
    required_evidence: tuple[EvidenceRequirement, ...],
    required_observed_evidence: tuple[EvidenceRequirement, ...],
) -> None:
    token_usage = result.token_usage
    event_coverage = result.event_coverage
    missing_observed_evidence = sorted(
        set(required_observed_evidence) - set(event_coverage.normalized_evidence_types)
    )
    attributes: dict[str, object] = {
        "evaluation.invocation_seconds": result.invocation_seconds,
        "evaluation.event_count": len(result.events),
        "evaluation.token_usage_source": token_usage.source,
        "evaluation.model_ids": list(result.model_ids),
        "evaluation.required_evidence": list(required_evidence),
        "evaluation.required_observed_evidence": list(required_observed_evidence),
        "evaluation.normalized_evidence_types": list(
            event_coverage.normalized_evidence_types
        ),
        "evaluation.unknown_event_types": list(event_coverage.unknown_event_types),
        "evaluation.unknown_event_type_count": len(event_coverage.unknown_event_types),
        "evaluation.unobserved_required_evidence": missing_observed_evidence,
    }
    token_counts = token_usage.available_counts()
    if {"input_tokens", "output_tokens", "total_tokens"} <= token_counts.keys():
        attributes["mlflow.chat.tokenUsage"] = {
            "input_tokens": token_counts["input_tokens"],
            "output_tokens": token_counts["output_tokens"],
            "total_tokens": token_counts["total_tokens"],
        }
    attributes.update(
        {
            f"evaluation.tokens.{name.removesuffix('_tokens')}": count
            for name, count in token_counts.items()
        }
    )
    span.set_attributes(attributes)
    span.set_outputs(
        {
            "event_count": len(result.events),
            "model_ids": result.model_ids,
            "required_evidence": required_evidence,
            "required_observed_evidence": required_observed_evidence,
            "unobserved_required_evidence": missing_observed_evidence,
            "event_coverage": event_coverage.to_dict(),
            "token_usage": token_usage.to_dict(),
        }
    )


def _record_agent_event(event: AgentEvent) -> None:
    span_type = SpanType.AGENT if event.category == "agent" else SpanType.TOOL
    with mlflow.start_span(
        name=f"{event.category}.{event.name}",
        span_type=span_type,
    ) as span:
        attributes = {
            "evaluation.evidence_type": event.evidence_type,
            "evaluation.event_status": event.status,
            "evaluation.observation_span": True,
            **dict(event.attributes),
        }
        span.set_attributes(attributes)
        span.set_inputs(dict(event.attributes))
        span.set_outputs({"status": event.status})
        if event.status.lower() in {"cancelled", "error", "failed"}:
            span.set_status("ERROR")
