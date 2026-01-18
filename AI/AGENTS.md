# AGENTS.md / CLAUDE.md

## Planning

Always create a plan first. Have the plan and spec reviewed before proceeding with implementation.

## Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.

## Coding Style

- Small, testable functions
- Early returns over nested conditionals
- Defensive coding: use guards and type narrowing even without strict mode
- Write docstrings. Conventions: typescript/tsx (TSDoc), python (google docstrings), go (GoDoc)
- Comments explain why, not what - provide enough context for someone to write tests against intended behaviour

## Testing

Always use test driven development when writing functions. Write tests first, then write code to make them pass. Make sure to use skills to help with this.

Only applies when a testing framework is already configured - do not set up testing infrastructure unprompted.

## When Uncertain

- Always ask before proceeding
- One decision at a time - don't present branching decisions that require multiple follow-ups. Instead, make a note and should circle back when needed.
- When presenting alternatives: pros, cons, and a recommendation given the context

## When Exploring and Reviewing

- Question my approach if you see issues
- Focus on: bugs, security, performance, architectural concerns
- Minor stylistic nitpicks can be noted as an aside
- Stop and ask before making significant changes
