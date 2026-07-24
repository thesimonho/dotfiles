"""Render normalized agent evidence as one readable MLflow span tree."""

from __future__ import annotations

from collections.abc import Callable

import mlflow
from agent import AgentResult
from agent_evidence import AgentEvent
from mlflow.entities import LiveSpan, SpanType


def invoke_traced_agent(invoke: Callable[[], AgentResult]) -> AgentResult:
    """Run an agent beneath the active case trace and attach safe evidence."""
    with mlflow.start_span(name="agent.invoke", span_type=SpanType.AGENT) as span:
        result = invoke()
        _describe_agent_invocation(span, result)
        for event in result.events:
            _record_agent_event(event)
        return result


def _describe_agent_invocation(span: LiveSpan, result: AgentResult) -> None:
    token_usage = result.token_usage
    attributes: dict[str, object] = {
        "evaluation.invocation_seconds": result.invocation_seconds,
        "evaluation.event_count": len(result.events),
        "evaluation.token_usage_source": token_usage.source,
        "evaluation.model_ids": list(result.model_ids),
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
            "evaluation.event_status": event.status,
            "evaluation.observation_span": True,
            **dict(event.attributes),
        }
        span.set_attributes(attributes)
        span.set_inputs(dict(event.attributes))
        span.set_outputs({"status": event.status})
        if event.status.lower() in {"cancelled", "error", "failed"}:
            span.set_status("ERROR")
