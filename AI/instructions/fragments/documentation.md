# Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.

## Doc lifecycle & archiving

Keep `/docs`, READMEs, APIs, and other documentation up to date.

Organize docs by how they age, not just by kind:

- **Living** — evergreen truth, edited in place (specs, references).
- **Snapshot** — true as-of a date, then frozen (research, durable local plans, mockups). Give each a status; when it ships or is superseded, move it into a sibling `archive/` subdir so the live folder shows only current docs. A superseded file gets a one-line banner at its top naming what replaced it.

A temporary plan for tracker-backed delivery is not a documentation snapshot: after its requirements have been transferred to the relevant delivery tickets, remove the local artifact. Durable local plans still use the snapshot lifecycle above.

## File-scoped agent directives (frontmatter)

A markdown doc can carry optional `agent:` frontmatter that agent tooling reads. All fields are optional; a doc without it behaves normally. This is general-purpose — pair any doc with any path it cares about, not just a codemap with its source directory. A roadmap tracking `src/**` (flag shipped items for removal), a vision doc tracking `docs/plans/**` (re-read whenever plans change), a style guide tracking a lint config, are all equally valid uses.

Add this to docs you create if the instruction can be scoped to a path.

- `instruction` — a short directive re-surfaced whenever the file is read or edited (e.g. a roadmap's "remove items as they complete", a codemap's "update when the mapped directory changes").
- `on-change` — a glob or list of globs; when a matching file is read or edited, this doc's instruction is surfaced, before the area gets worked blind. Throttled to once per doc per hour, not on every touch.

Example — couple a codemap to its source directory:

```yaml
---
agent:
  instruction: Update this codemap when the mapped directory changes.
  on-change:
    - "src/features/**"
---
```
