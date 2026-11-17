# Workflow

## Core Principles

These are the core principles you must follow for your work:

1. Define success criteria.
2. Don't assume. Don't hide confusion. Surface tradeoffs.
3. Minimum code that solves the problem. Nothing speculative.
4. Keep changes focused. When work exposes nearby duplication, an oversized file, or a misleading boundary, make a small related improvement if you can verify it safely. Do not expand the task into a broad refactor without authorization.

## Maintainability

- Before adding a file or abstraction, inspect the surrounding directory and look for existing code that can serve the same purpose.
- Group related code by feature and responsibility. Repeated filename prefixes can signal that a subdirectory is needed. Avoid repeating a directory name in every filename when the context is already clear.
- Prefer a cohesive file over many tiny files. When a handwritten file approaches 800 lines, look for a natural responsibility to extract. Treat this as a soft limit, not a reason to split code arbitrarily.
- Reuse equivalent helpers, components, types, and schemas when they have the same behavior and a clear owner. Do not create a generic abstraction for similarities that are only superficial.
- Follow the project's import and formatting conventions. Prefer project-root aliases across directories and relative imports within a directory, when the relevant runtime supports them.
- When moving code, check callers, scripts, tests, configuration, and file-relative paths. Preserve behavior and verify the affected paths.
- Apply these rules to tests and scripts as well as application code. Generated code and vendor assets are exempt.

## Project Management

When a repository has a GitHub Project or issue tracker, use the `kanban` skill to keep delivery state current. GitHub is the operational source of truth for tracked work; follow local conventions for small or untracked repositories.

For tracker-backed work:

- Read the ticket and relevant milestone state once at ticket start.
- Update the tracker and relevant tickets when their status materially changes.
- Perform one final synchronization after the PR is merged.

### Future Issues

If an item arises that is not related to a current issue or milestone (e.g. an irreproducible bug, feature idea, out of scope changes), it should be logged so it is not forgotten:

- Tracked: create a new GitHub issue with the label `needs-triage`
- Untracked: add it to a `TODO.md` doc (untracked, local only)

If there are a set of related issues, consider creating a new milestone for them.

## Escalation to an advisor

If you have spent more than 3 attempts trying to fix a problem, you must pause and escalate the issue to an `advisor` agent. The `advisor` is spawned as a strong model with higher reasoning effort. You're pre-approved to spawn that subagent.

Explain where you are in the project, the problem you're having, and what you have tried. They do not have your full context, only your description and the code, so make sure your description is thorough. Give them time to diagnose, and interact with them to arrive at a solution together.

Remove the subagent when they're done.

## When Responding

- Start with the big picture. ELI5 your explanation/solution. Assume the user doesn't know anything.
- Write in ASD-STE100 Simplified Technical Language.
- If code was edited, provide a bulleted list of key files that were changed and summary of what changes were made.
- Suggest next steps.
