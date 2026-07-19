"""Tier-dispatched scoring logic for MLflow evaluation cases."""

import agent


def score_output_quality(
    output: str,
    rubric: str,
    profile: str = "claude",
) -> tuple[bool, str]:
    """LLM-judge tier: shells to the selected authenticated agent CLI."""
    judge_prompt = (
        f"Judge whether this output satisfies the rubric below. "
        f"Reply with exactly the word PASS or the word FAIL, nothing else.\n\n"
        f"Rubric: {rubric}\nOutput: {output}"
    )
    verdict_raw = agent.run_judge(judge_prompt, profile=profile)
    passed = "PASS" in verdict_raw.upper() and "FAIL" not in verdict_raw.upper()
    return passed, verdict_raw[:200]


def score_trajectory(output: str, expected_mention: str) -> tuple[bool, str]:
    """Deterministic tier: no LLM judge involved."""
    passed = expected_mention.lower() in output.lower()
    return passed, f"looked for '{expected_mention}' in the raw output"


def score_case(
    output: str,
    case: dict,
    profile: str = "claude",
) -> tuple[bool, str]:
    if case["tier"] == "output-quality":
        return score_output_quality(output, case["rubric"], profile=profile)
    if case["tier"] == "trajectory":
        return score_trajectory(output, case["expected_mention"])
    raise ValueError(f"unknown tier: {case['tier']}")
