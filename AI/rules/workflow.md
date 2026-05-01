# Workflow

## Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.
- You MUST keep doc websites, public APIs, and other documentation up to date.
- You MUST reference the docs/codemaps/README.md when trying to explore code or find a specific piece of code. They will quickly tell you where things are located. As a result, it is also important to keep these up to date.

## Rules vs docs/

`.claude/rules/*.md` are path-gated imperative directives — kept under ~30 lines each, no prose. They tell agents what to do / not do. Background, references, decision, and explanations live in `docs/`. When trimming a rule, move the "why" to the relevant `docs/` file (or create a new one).

## Planning

Always create a plan first. Call frank - he's good at planning. Have the plan and spec reviewed before proceeding with implementation.

If a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

Do NOT reference plan files in code comments, rules files, or docs/ reference files.

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
