---
name: simplify
description: Review recently changed code with three separate read-only agents for reuse, quality, and efficiency, then return prioritized issue lists. Use after implementing multi-file changes, before commit, or when the user asks to simplify, clean up, reduce duplication, or review recent changes.
user-invocable: true
---

# Simplify

Review recent code changes through three lenses: reuse, code quality, and efficiency. Do not edit files. Return prioritized findings for the main agent or user to decide what to fix next.

If I ask you to run the /simplify skill, then I'm also giving you direct permission to spawn any required subagents for the tasks.

## Workflow

### 1. Scope the Review

Prefer the smallest meaningful scope:

1. Files or paths named by the user.
2. Current git changes.
3. Files edited in the current session.
4. Recently modified tracked files, only when the user asked for a cleanup pass and no diff exists.

Use the narrowest accurate diff command for git changes:

- `git status --short` first, to identify staged, unstaged, and untracked paths.
- `git diff` for unstaged changes.
- `git diff --cached` for staged changes.
- Both commands when staged and unstaged changes coexist.
- Read untracked text files directly, or use `git diff --no-index /dev/null -- <path>` when a diff-shaped view is useful.
- The exact branch, commit, or path comparison requested by the user.

If there is no clear review scope, stop and say that briefly.

Before judging code, read the nearest applicable instructions and docs for the touched area: `AGENTS.md`, `CLAUDE.md`, subdirectory `README.md`, codemaps, architecture notes, or workflow docs. Treat those as source-of-truth constraints.

### 2. Spawn Three Review Agents

Launch three read-only reviewers in parallel when the active environment supports delegation. For a tiny diff or a runtime without subagents, run the same three reviewer roles locally as separate passes and keep the output separated.

Give every reviewer the same scope and instruct them not to edit files, stage changes, commit, or mutate the workspace. Each reviewer returns only prioritized findings for its assigned lens.

Each finding must include:

1. Priority: high, medium, or low.
2. File and line, or nearest symbol.
3. Problem.
4. Why it matters.
5. Recommended fix.
6. Confidence: high, medium, or low.

#### Agent 1: Reuse Review

Look for newly written code that should reuse existing project behavior:

- Existing helpers, utilities, hooks, components, commands, constants, schemas, or domain services that already solve the problem.
- Duplicate or near-duplicate functions introduced by the change.
- Inline logic that hand-rolls common behavior such as path handling, string parsing, environment checks, type guards, date handling, validation, or request shaping.
- Similar patterns in utility directories, shared modules, and files adjacent to the changed code.

Prefer existing local APIs over new abstraction. Recommend a new helper only when duplication is real and the helper has a clear owner.

#### Agent 2: Quality Review

Look for maintainability and local-standard issues:

- Redundant state or cached values that can be derived directly.
- Parameter sprawl that threads context through too many layers.
- Copy-paste blocks with slight variation.
- Leaky abstractions or module boundary violations.
- Stringly typed logic where constants, enums, unions, schemas, or typed helpers already exist.
- Unnecessary JSX wrappers or elements that add no layout value when child component props already express the layout.
- Deep nesting, including chained ternaries, nested `if` or `else` blocks, and `switch` logic 3 or more levels deep.
- Unclear names, dead code, redundant comments, or overly clever expressions.
- Comments that explain what obvious code does, narrate the change, reference the task, or mention the caller instead of preserving non-obvious why.
- Missing docstrings for new non-trivial functions when the project expects them.

Keep code sentence-readable. Prefer clear variables and early returns over compact expressions.

#### Agent 3: Efficiency Review

Look for avoidable cost or runtime risk:

- Duplicate reads, repeated computations, repeated API calls, or N+1 patterns.
- Independent async work that is needlessly sequential.
- New work added to startup, render, request, or hot loops without need.
- Recurring no-op updates in polling loops, intervals, subscriptions, or event handlers that notify consumers even when state did not change.
- Wrapper update functions that ignore the project's no-change signal, such as same-reference reducer returns.
- Pre-checks for existence where the operation should run directly and handle the error.
- Unbounded collections, missing cleanup, event listener leaks, or subscription leaks.
- Broad scans or full-file reads when the code only needs a narrow subset.

Common performance issues:

1. **Algorithmic Complexity**: O(n²) or worse where O(n) is possible
2. **Database Queries**: N+1 queries, missing indexes, full table scans
3. **Memory Usage**: Unbounded growth, large allocations, leaks
4. **I/O Operations**: Synchronous blocking, missing batching
5. **Caching**: Missing cache opportunities, invalidation issues
6. **Network**: Excessive requests, missing compression, large payloads
7. **Concurrency**: Lock contention, missing parallelization
8. **Resource Management**: Connection pools, file handles, cleanup

Ignore theoretical performance concerns unless they point to a concrete change in the reviewed code.

### 3. Aggregate Findings

Wait for all three reviewers to finish. Combine their results without losing which reviewer reported each finding.

Deduplicate overlapping findings and discard weak, speculative, or instruction-conflicting items. Prioritize real issues over style preferences.

Report findings in this order:

1. High-priority issues across all reviewers.
2. Medium-priority issues across all reviewers.
3. Low-priority issues or optional cleanups.
4. Clean reviewer sections with no findings.

Within each priority group, preserve the reviewer category: reuse, quality, or efficiency.

### 4. Do Not Fix

This skill is review-only. Do not apply patches, run formatters, update tests, stage changes, commit, push, or delete files.

If a finding has an obvious safe fix, describe it in the recommendation. Leave the workspace unchanged.

Ask before taking on follow-up implementation, especially for broad architectural rewrites, public API changes, schema changes, behavior changes, dependency swaps, or large file moves.

### 5. Report

Close with a concise review report:

- What scope was reviewed.
- Which three reviewers ran.
- Prioritized findings with category and confidence.
- Any reviewer that found no issues.
- Confirmation that no files were changed.

If all three reviewers find nothing worth raising, say the reviewed scope is clean for this rubric.
