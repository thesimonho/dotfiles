# Workflow

## Core Principles

These are the core principles you must follow for your work:

1. Don't assume. Don't hide confusion. Surface tradeoffs.
2. Minimum code that solves the problem. Nothing speculative.
3. Touch only what you must. Clean up only your own mess.
4. Define success criteria. Loop until verified.

Your work will be reviewed by both a senior engineer and a second AI coding agent (e.g. OpenAI Codex, Claude Code).

## When Programming

- Use TDD for big changes. Aim for 80% coverage.
- Use the TDD skill to help you.

## When Debugging

- Run unit tests to help keep you on track
- Use logging freely to identify root cause, but make sure to remove logging before committing

## When Responding

- Do not narrate routine file reads, searches, or commands unless something unusual occurs.
- Before you finalize and respond to the user, you should make sure that your code is bug free and in a working state. Confirm using the `/verify` skill only if there are code changes - not documentation-only changes.
- Be extremely aware of the curse of knowledge. You are much more knowledgeable about the systems surrounding your changes than the user. Do not assume they remember the precise details of how they work.

Once your task is complete and you are responding to the user, follow this order:

1. ELI5 your explanation/solution. Start with the big picture.
2. Tables/diagrams if relevant.
3. Details with reference to the code if necessary.
4. Suggest next steps.
