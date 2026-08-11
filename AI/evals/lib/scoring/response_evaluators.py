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
    """Return the first line that leads with exactly one verdict token.

    Claude answers "PASS: reason" on one line while Codex follows the two-line
    format literally, so a leading token is the signal. Judges also open with
    framing that names both outcomes ("PASS or FAIL judgment doesn't require
    exploration"), which read as a verdict when only the first line counted and
    silently inverted a FAIL. A line naming both tokens states the task rather
    than the answer, so skip it and keep looking for the real verdict below.
    """
    for line in verdict_raw.strip().splitlines():
        normalized_line = line.upper()
        names_pass = "PASS" in normalized_line
        names_fail = "FAIL" in normalized_line
        if names_pass and names_fail:
            continue
        verdict_match = re.match(r"^[^A-Z]*(PASS|FAIL)\b", normalized_line)
        if verdict_match is not None:
            return verdict_match.group(1)
    return None


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


def score_judged_completion(
    output: str,
    rubric: str,
    context: AgentExecutionContext,
    profile: str = "claude",
    environment_overrides: dict[str, str] | None = None,
) -> tuple[str, str]:
    """Classify completion a rubric defines, for cases words cannot settle.

    Most cases finish by naming concrete things, and matching those is exact
    and cheap. A case whose completion is a judgement has no such list: the
    security case was recorded as unfinished for describing an authentication
    bypass without calling it "critical". There is no partial verdict to give
    when one rubric decides the question.
    """
    score, rationale = score_output_quality(
        output,
        rubric,
        context,
        profile=profile,
        environment_overrides=environment_overrides,
    )
    return ("COMPLETE" if score > 0 else "FAILED"), rationale


def _evaluate_output_completion(
    metric: OutputCompletionMetric,
    evidence: ResponseEvidence,
) -> ScoredMetric:
    rubric = metric.get("completion_rubric")
    if rubric is None:
        return score_output_completion(
            evidence.output,
            tuple(metric.get("required_mentions", ())),
        )
    if evidence.context is None:
        raise ValueError("judged completion metrics require a judge context")
    return score_judged_completion(
        evidence.output,
        str(rubric),
        evidence.context,
        profile=evidence.profile,
        environment_overrides=evidence.environment_overrides,
    )


RESPONSE_EVALUATORS = {
    "output-contains": _evaluate_output_contains,
    "output-contains-all": _evaluate_output_contains_all,
    "output-quality": _evaluate_output_quality,
    "output-completion": _evaluate_output_completion,
}
