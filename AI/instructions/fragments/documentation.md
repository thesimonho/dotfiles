# Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.
- Keep doc websites, public APIs, and other documentation up to date.
- Reference the docs/codemaps/README.md, if available, when trying to explore code or find a specific piece of code. They will quickly tell you where things are located. As a result, it is also important to keep these up to date.

## Agent Instructions vs docs/

Project-local agent instructions are imperative directives, not background prose. Prefer the project’s existing portable instruction surface (`AGENTS.md` or equivalent). Use Claude-specific `.claude/rules/*.md` when the project already uses Claude Code rules or the user asks for them.

Keep imperative instruction files short and actionable. Background, references, decisions, and explanations live in `docs/`. When trimming an instruction, move the "why" to the relevant `docs/` file (or create a new one).

## Markdown vs HTML

Pick the format based on the reader, not the author.

- **Markdown** — for agent-facing docs: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/codemaps/**`, rule files. Linear text is what agents consume best.
- **HTML** — for human-facing docs under `docs/plans/**` (implementation plans, specs).

### Writing HTML plans

When creating a plan under `docs/plans/`, write a single self-contained `.html` file (inline CSS, no external assets).

Keep the HTML structure as simple as possible and well spaced. Don't use `<div>` `<span>` `<p>` tags unless you need to.

Structure:

- **TL;DR header** with summary/overview.
- **Numbered sections** (`01`, `02`, …) — readers cite them as anchors.

Freely use visual components to aid comprehension. Examples:

- **Tables** for risks, trade-offs, decision matrices, content-to-structure mappings.
- **Accordions** for collapsible sections. Sections that refer to completed/resolved work should be collapsed by default.
- **Tabs** for different phases/major sections.
- **Side-by-side blocks** for before/after, request/response, option1/option2.
- **Mermaid diagrams** for paths, data flow, architecture. Caption them; label edges.
- **Callouts** for trust boundaries, gotchas, open questions — visually distinct from prose.
- **Chips** (`HIGH`, `MED`, `LOW`, `Completed`) as inline spans, not prose.
- **Code blocks** with the file path as a header and `file:line` references back to source.

Do NOT produce a wall of `<p>` tags. If the content would render the same in markdown, you picked the wrong format — find the spatial structure (table, diagram, side-by-side) before writing.
