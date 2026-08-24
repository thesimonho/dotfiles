# Workflow

## Core Principles

These are the core principles you must follow for your work:

1. Define success criteria.
1. Don't assume. Don't hide confusion. Surface tradeoffs.
1. Minimum code that solves the problem. Nothing speculative.
1. Touch only what you must. Clean up only your own mess.

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
- Suggest next steps.
