"""Evaluators whose evidence is the agent's final response text."""

import re
from dataclasses import dataclass

import agent
from agent_execution_context import AgentExecutionContext
from evaluation_case import (
    OutputCompletionMetric,
    OutputContainsAllMetric,
    OutputContainsMetric,
    OutputQualityMetric,
)

type MetricValue = bool | int | float | str
type ScoredMetric = tuple[MetricValue, str] | None


@dataclass(frozen=True)
class ResponseEvidence:
    """Everything a response-derived evaluator may consult."""

    output: str
    context: AgentExecutionContext | None
    profile: str
    environment_overrides: dict[str, str] | None


def score_output_quality(
    output: str,
    rubric: str,
    context: AgentExecutionContext,
    profile: str = "claude",
    environment_overrides: dict[str, str] | None = None,
) -> tuple[float, str]:
    """Judge response quality through the selected authenticated agent CLI."""
    judge_prompt = (
        f"Judge whether this output satisfies the rubric below. "
        f"Reply with PASS or FAIL on the first line, followed by one concise "
        f"sentence explaining the verdict.\n\n"
        f"Rubric: {rubric}\nOutput: {output}"
    )
    verdict = None
    verdict_raw = ""
    for _ in range(2):
        verdict_raw = agent.run_judge(
            judge_prompt,
            context,
            profile=profile,
            environment_overrides=environment_overrides,
            model=context.agent_model,
            effort=context.agent_effort,
        )
        verdict = _parse_judge_verdict(verdict_raw)
        if verdict is not None:
            break
    if verdict is None:
        raise RuntimeError("evaluation judge did not return PASS or FAIL")
    return (100.0 if verdict == "PASS" else 0.0), verdict_raw[:1000]


def _parse_judge_verdict(verdict_raw: str) -> str | None:
    """Accept a leading verdict token; judges occasionally add framing once.

    Claude answers "PASS: reason" on one line while Codex follows the
    two-line format literally, so only the first line's leading token counts.
    """
    stripped_verdict = verdict_raw.strip()
    if not stripped_verdict:
        return None
    first_line = stripped_verdict.splitlines()[0].upper()
    verdict_match = re.match(r"^[^A-Z]*(PASS|FAIL)\b", first_line)
    return verdict_match.group(1) if verdict_match else None


def score_expected_mention(output: str, expected_mention: str) -> tuple[bool, str]:
    """Check the final response for required text without invoking a judge."""
    passed = expected_mention.lower() in output.lower()
    outcome = "contained" if passed else "did not contain"
    return passed, f"final response {outcome} '{expected_mention}'"


def score_expected_mentions(
    output: str,
    expected_mentions: tuple[str, ...],
) -> tuple[bool, str]:
    """Check that every required value appears in the final response."""
    missing_mentions = [
        mention
        for mention in expected_mentions
        if mention.lower() not in output.lower()
    ]
    if not missing_mentions:
        return True, "final response contained every expected mention"
    return False, f"final response missed: {', '.join(missing_mentions)}"


def score_output_completion(
    output: str,
    required_mentions: tuple[str, ...],
) -> tuple[str, str]:
    """Classify deterministic response completion without a judge."""
    matched_mentions = tuple(
        mention for mention in required_mentions if mention.lower() in output.lower()
    )
    if len(matched_mentions) == len(required_mentions):
        completion = "COMPLETE"
    elif matched_mentions:
        completion = "PARTIAL"
    else:
        completion = "FAILED"
    missing_mentions = tuple(
        mention for mention in required_mentions if mention not in matched_mentions
    )
    rationale = f"matched {len(matched_mentions)} of {len(required_mentions)} outcomes"
    if missing_mentions:
        rationale += f"; missing: {', '.join(missing_mentions)}"
    return completion, rationale


def _evaluate_output_contains(
    metric: OutputContainsMetric,
    evidence: ResponseEvidence,
) -> ScoredMetric:
    return score_expected_mention(evidence.output, metric["expected_mention"])


def _evaluate_output_contains_all(
    metric: OutputContainsAllMetric,
    evidence: ResponseEvidence,
) -> ScoredMetric:
    return score_expected_mentions(
        evidence.output,
        tuple(metric["expected_mentions"]),
    )


def _evaluate_output_quality(
    metric: OutputQualityMetric,
    evidence: ResponseEvidence,
) -> ScoredMetric:
    if evidence.context is None:
        raise ValueError("output-quality metrics require a judge context")
    return score_output_quality(
        evidence.output,
        metric["rubric"],
        evidence.context,
        profile=evidence.profile,
        environment_overrides=evidence.environment_overrides,
    )


def _evaluate_output_completion(
    metric: OutputCompletionMetric,
    evidence: ResponseEvidence,
) -> ScoredMetric:
    return score_output_completion(
        evidence.output,
        tuple(metric["required_mentions"]),
    )


RESPONSE_EVALUATORS = {
    "output-contains": _evaluate_output_contains,
    "output-contains-all": _evaluate_output_contains_all,
    "output-quality": _evaluate_output_quality,
    "output-completion": _evaluate_output_completion,
}
