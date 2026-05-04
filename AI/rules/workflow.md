# Workflow

Your work will be reviewed by both a senior engineer and a second AI coding agent (e.g. OpenAI Codex).

## Planning

Always create a plan first. Call frank - he's good at planning. Have the plan and spec reviewed before proceeding with implementation.

If a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

Do NOT reference plan files in code comments, rules files, or docs/ reference files.

Delete the plan file after the work is complete.

## When Uncertain

- Always ask before proceeding
- One decision at a time - don't present branching decisions that require multiple follow-ups. Instead, make a note and should circle back when needed.
- When presenting alternatives: pros, cons, and a recommendation given the context

## When Exploring and Reviewing

- Question my approach if you see issues
- Focus on: bugs, security, performance, architectural concerns
- Minor stylistic nitpicks can be noted as an aside
- Stop and ask before making significant changes

## When debugging

- Run unit tests to help keep you on track
- Use logging freely to identify root cause, but make sure to remove logging before committing
- When fixing frontend issues, make sure you proactively use the agent browser skill in headed mode

## Code Intelligence

For an LSP-centric workflow, you should declare/initialize before you use/reference a variable, otherwise you'll be flooded with stale errors.

Prefer LSP over Grep/Glob/Read for code navigation:

- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

Before renaming or changing a function signature, use `findReferences` to find all call sites first.

Use Grep/Glob only for text/pattern searches (comments, strings, config values) where LSP doesn't help.

After writing or editing code, check LSP diagnostics before moving on. Fix any type errors or missing imports immediately, even if they're not in your domain.
