# Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Reference `/docs/codemaps/README.md`, if available, when trying find a specific piece of code. It will quickly tell you where things are located. As a result, it is also important to keep these up to date.
- When creating markdown files, do not use hard line breaks; let text wrap naturally.

## Doc lifecycle & archiving

Keep `/docs`, READMEs, APIs, and other documentation up to date.

Sort docs by how they age, not just by kind:

- **Living** — evergreen truth, edited in place (specs, references, codemaps).
- **Snapshot** — true as-of a date, then frozen (research, plans, mockups). Give each a status; when it ships or is superseded, move it into a sibling `archive/` subdir so the live folder shows only current docs. A superseded file gets a one-line banner at its top naming what replaced it.

An index (`docs/README.md`) maps only the **live** docs — don't enumerate archived files, the `archive/` folder is its own list. For work that's relevant later, put a "revisit-when" trigger in the roadmap/backlog, not buried in the doc.

## File-scoped agent directives (frontmatter)

A markdown doc can carry optional `agent:` frontmatter that agent tooling reads. Both fields are optional; a doc without it behaves normally.

Add this to docs you create if the instruction can be scoped to a path.

- `instruction` — a short directive re-surfaced whenever the file is read or edited (e.g. a roadmap's "remove items as they complete", a codemap's "update when the mapped directory changes").
- `on-change` — a glob or list of globs; when a matching file changes in a session but this doc does not, the agent is reminded at turn-end.

Example: use it to couple a codemap to its source directory, or the docs index to `docs/**`:

```yaml
---
agent:
  instruction: Update this codemap when the mapped directory changes.
  on-change:
    - "src/features/**"
---
```

## Agent Instructions vs docs/

Project-local agent instructions are imperative directives, not background prose. Prefer the project’s existing portable instruction surface (`AGENTS.md` or equivalent). Use Claude-specific `.claude/rules/*.md` when the project already uses Claude Code rules or the user asks for them.

Keep instruction files short and actionable. Background, references, decisions, and explanations live in `docs/`. When trimming an instruction, move the "why" to the relevant `docs/<file>` (or create a new one).
