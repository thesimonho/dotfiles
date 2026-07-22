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

A markdown doc can carry optional `agent:` frontmatter that agent tooling reads. All fields are optional; a doc without it behaves normally. This is general-purpose — pair any doc with any path it cares about, not just a codemap with its source directory. A roadmap tracking `src/**` (flag shipped items for removal), a vision doc tracking `docs/plans/**` (re-read whenever plans change), a style guide tracking a lint config, are all equally valid uses.

Add this to docs you create if the instruction can be scoped to a path.

- `instruction` — a short directive re-surfaced whenever the file is read or edited (e.g. a roadmap's "remove items as they complete", a codemap's "update when the mapped directory changes").
- `on-change` — a glob or list of globs; the first time (per session) a matching file is read or edited, this doc's instruction is surfaced, before the area gets worked blind. Fires once per doc per session, not on every touch.

Example — couple a codemap to its source directory:

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

When a project supports agent worktrees, keep the imperative bootstrap sequence in `AGENTS.md` and put the detailed runbook in contributor docs. The runbook should identify:

- The exact locked dependency-install command required for new or moved worktrees.
- Which ignored configuration belongs to the canonical checkout and how worktrees consume it without copying or committing secrets.
- Which local services are shared versus worktree-owned, including who may start, reset, migrate, or stop them.
- How application ports, caches, build output, browser sessions, and verification artifacts avoid collisions.
- The verification gate and the evidence required from a real worktree.
- Known exceptions, such as branches that change a shared service's schema and therefore require an isolated instance.
