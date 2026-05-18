# Workflow

## Core Principles

These are the core principles you must follow for your work:

1. Don't assume. Don't hide confusion. Surface tradeoffs.
2. Minimum code that solves the problem. Nothing speculative.
3. Touch only what you must. Clean up only your own mess.
4. Define success criteria. Loop until verified.

Your work will be reviewed by both a senior engineer and a second AI coding agent (e.g. OpenAI Codex, Claude Code).

## When Planning

For multi-file code changes, create a plan first. Call the frank agent - he's good at planning. Have the plan and spec reviewed before proceeding with implementation.

Plan file names should start with a date and time stamp YYYYMMDD, eg `20231201-<name>.md`.

If a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

Do NOT reference plan files in code comments, rules files, or docs/ reference files.

Keep the plan file up to date, use Todo/Task list while working through it.

## When Uncertain

- Always ask before proceeding
- One decision at a time - don't present branching decisions that require multiple follow-ups. Instead, make a note and should circle back when needed.
- When presenting alternatives: pros, cons, and a recommendation given the context

## When Exploring and Reviewing

- Question my approach if you see issues
- Focus on: bugs, security, performance, architectural concerns
- Minor stylistic nitpicks can be noted as an aside
- Stop and ask before making significant changes

## When Debugging

- Run unit tests to help keep you on track
- Use logging freely to identify root cause, but make sure to remove logging before committing
- When fixing frontend issues, make sure you proactively use the agent browser skill in headed mode

## When responding

Once your task is complete and you are responding to the user, you should end by suggesting potential next steps.
