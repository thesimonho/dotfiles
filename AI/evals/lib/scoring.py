"""Tier-dispatched scoring logic for MLflow evaluation cases."""

import agent
from agent_execution_context import AgentExecutionContext


def score_output_quality(
    output: str,
    rubric: str,
    context: AgentExecutionContext,
    profile: str = "claude",
) -> tuple[bool, str]:
    """LLM-judge tier: shells to the selected authenticated agent CLI."""
    judge_prompt = (
        f"Judge whether this output satisfies the rubric below. "
        f"Reply with PASS or FAIL on the first line, followed by one concise "
        f"sentence explaining the verdict.\n\n"
        f"Rubric: {rubric}\nOutput: {output}"
    )
    verdict_raw = agent.run_judge(judge_prompt, context, profile=profile)
    verdict = verdict_raw.strip().splitlines()[0].upper()
    if verdict not in {"PASS", "FAIL"}:
        raise RuntimeError("evaluation judge did not return PASS or FAIL")
    return verdict == "PASS", verdict_raw[:1000]


def score_expected_mention(output: str, expected_mention: str) -> tuple[bool, str]:
    """Check the final response for required text without invoking a judge."""
    passed = expected_mention.lower() in output.lower()
    outcome = "contained" if passed else "did not contain"
    return passed, f"final response {outcome} '{expected_mention}'"


def score_case(
    output: str,
    case: dict,
    context: AgentExecutionContext,
    profile: str = "claude",
) -> tuple[bool, str]:
    if case["tier"] == "output-quality":
        return score_output_quality(
            output,
            case["rubric"],
            context,
            profile=profile,
        )
    if case["tier"] == "output-contains":
        return score_expected_mention(output, case["expected_mention"])
    raise ValueError(f"unknown tier: {case['tier']}")
