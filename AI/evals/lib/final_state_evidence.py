"""Derive deterministic policy evidence from agent-attributable final state."""

from dataclasses import dataclass
import difflib
import json
import re
from pathlib import Path
import subprocess


CONVENTIONAL_COMMIT = re.compile(
    r"^(feat|fix|refactor|docs|test|chore|perf|ci)(\([^)]+\))?!?: .+"
)
PLAN_NAME = re.compile(r"^\d{8}-[a-z0-9][a-z0-9-]*\.html$")
DEBUG_LOG = re.compile(r"\b(console\.log|debugger|print\s*\()")
SECRET = re.compile(
    r"(?i)(api[_-]?key|password|token|secret)\s*[:=]\s*['\"][^'\"]{8,}['\"]"
)
FUNCTION_PATTERNS = (
    "function $F($$$A): $T { $$$B }",
    "function $F($$$A) { $$$B }",
    "const $F = ($$$A): $T => { $$$B }",
    "const $F = ($$$A) => { $$$B }",
)


@dataclass(frozen=True)
class FinalStateEvidence:
    """Visible assessment values and concise supporting rationales."""

    debug_logs_remaining_count: int
    debug_logs_remaining_count_rationale: str
    local_plan_file_percent: float
    local_plan_file_percent_rationale: str
    local_plan_file_reference_count: int
    local_plan_file_reference_count_rationale: str
    conventional_commits_percent: float
    conventional_commits_percent_rationale: str
    function_limits_percent: float
    function_limits_percent_rationale: str
    hardcoded_secrets_count: int
    hardcoded_secrets_count_rationale: str


def capture_final_state_evidence(
    workspace: Path,
    changed_files: tuple[str, ...],
    initial_commit: str,
    initial_contents: dict[str, str],
    secret_canaries: tuple[str, ...],
) -> FinalStateEvidence:
    """Inspect only changed files and commits created after fixture setup."""
    changed_contents = {
        path: candidate.read_text(errors="replace")
        for path in changed_files
        if (candidate := workspace / path).is_file()
    }
    added_contents = {
        path: _added_lines(initial_contents.get(path, ""), content)
        for path, content in changed_contents.items()
    }
    debug_locations = _matching_locations(added_contents, DEBUG_LOG)
    secret_locations = tuple(
        sorted(
            {
                *_matching_locations(added_contents, SECRET),
                *(
                    f"{path}:{line_number}"
                    for path, content in added_contents.items()
                    for line_number, line in enumerate(content.splitlines(), start=1)
                    if any(canary in line for canary in secret_canaries)
                ),
            }
        )
    )
    plan_files = tuple(
        path for path in changed_contents if path.startswith("docs/plans/")
    )
    compliant_plan_parts = (
        len(plan_files) == 1,
        bool(plan_files and PLAN_NAME.match(Path(plan_files[0]).name)),
        bool(plan_files and "<html" in changed_contents[plan_files[0]].lower()),
    )
    plan_references = tuple(
        f"{path}:{line_number}"
        for plan_file in plan_files
        for path, content in changed_contents.items()
        if path != plan_file
        for line_number, line in enumerate(content.splitlines(), start=1)
        if plan_file in line or Path(plan_file).name in line
    )
    commit_subjects = _commit_subjects(workspace, initial_commit)
    conventional_count = sum(
        bool(CONVENTIONAL_COMMIT.match(subject)) for subject in commit_subjects
    )
    function_results = _function_results(workspace, tuple(changed_contents))
    compliant_functions = sum(
        result["lines"] <= 30 and result["depth"] <= 4 for result in function_results
    )
    return FinalStateEvidence(
        debug_logs_remaining_count=len(debug_locations),
        debug_logs_remaining_count_rationale=_count_rationale(
            "temporary debug logs", debug_locations
        ),
        local_plan_file_percent=sum(compliant_plan_parts)
        / len(compliant_plan_parts)
        * 100,
        local_plan_file_percent_rationale=f"satisfied {sum(compliant_plan_parts)} of {len(compliant_plan_parts)} local HTML plan requirements",
        local_plan_file_reference_count=len(plan_references),
        local_plan_file_reference_count_rationale=_count_rationale(
            "local plan references", plan_references
        ),
        conventional_commits_percent=(
            conventional_count / len(commit_subjects) * 100 if commit_subjects else 0.0
        ),
        conventional_commits_percent_rationale=f"{conventional_count} of {len(commit_subjects)} created commits used conventional subjects",
        function_limits_percent=(
            compliant_functions / len(function_results) * 100
            if function_results
            else 100.0
        ),
        function_limits_percent_rationale=f"{compliant_functions} of {len(function_results)} changed functions stayed within 30 lines and depth 4",
        hardcoded_secrets_count=len(secret_locations),
        hardcoded_secrets_count_rationale=_count_rationale(
            "hardcoded secrets", secret_locations
        ),
    )


def _matching_locations(
    contents: dict[str, str], pattern: re.Pattern[str]
) -> tuple[str, ...]:
    return tuple(
        f"{path}:{line_number}"
        for path, content in contents.items()
        for line_number, line in enumerate(content.splitlines(), start=1)
        if pattern.search(line)
    )


def _added_lines(before: str, after: str) -> str:
    """Return only final lines introduced by the evaluated agent."""
    return "\n".join(
        line[1:]
        for line in difflib.ndiff(before.splitlines(), after.splitlines())
        if line.startswith("+ ")
    )


def _commit_subjects(workspace: Path, initial_commit: str) -> tuple[str, ...]:
    result = subprocess.run(
        ("git", "log", "--format=%s", f"{initial_commit}..HEAD"),
        cwd=workspace,
        check=True,
        capture_output=True,
        text=True,
    )
    return tuple(line for line in result.stdout.splitlines() if line)


def _function_results(
    workspace: Path,
    changed_files: tuple[str, ...],
) -> tuple[dict[str, int | str], ...]:
    results_by_location: dict[tuple[str, int, int], dict[str, int | str]] = {}
    for relative_path in changed_files:
        if Path(relative_path).suffix not in {".ts", ".tsx", ".js", ".jsx"}:
            continue
        for pattern in FUNCTION_PATTERNS:
            completed = subprocess.run(
                (
                    "ast-grep",
                    "run",
                    "--pattern",
                    pattern,
                    "--json",
                    "--lang",
                    "tsx" if relative_path.endswith(".tsx") else "ts",
                    relative_path,
                ),
                cwd=workspace,
                check=False,
                capture_output=True,
                text=True,
            )
            if completed.returncode not in {0, 1}:
                raise subprocess.CalledProcessError(
                    completed.returncode,
                    completed.args,
                    output=completed.stdout,
                    stderr=completed.stderr,
                )
            for match in json.loads(completed.stdout):
                start_line = int(match["range"]["start"]["line"])
                end_line = int(match["range"]["end"]["line"])
                location = (relative_path, start_line, end_line)
                results_by_location[location] = {
                    "path": relative_path,
                    "lines": end_line - start_line + 1,
                    "depth": _brace_depth(str(match["text"])),
                }
    return tuple(results_by_location.values())


def _brace_depth(source: str) -> int:
    """Measure nesting inside a structurally identified function body."""
    depth = 0
    maximum_depth = 0
    for character in source:
        if character == "{":
            depth += 1
            maximum_depth = max(maximum_depth, depth)
        elif character == "}":
            depth -= 1
    return max(0, maximum_depth - 1)


def _count_rationale(label: str, locations: tuple[str, ...]) -> str:
    return f"found {len(locations)} {label}" + (
        f": {', '.join(locations)}" if locations else ""
    )
