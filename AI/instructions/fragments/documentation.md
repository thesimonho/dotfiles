# Documentation

## Directory READMEs

A directory's own `README.md` is where its context lives. Write one for any subdirectory or submodule whose purpose, constraints, or conventions are not obvious from its files.

## Doc lifecycle & archiving

Keep local documentation up to date. For docs that are superseded or no longer relevant (e.g. plans after merging the feature), archive them in a sibling `archive/` folder.

A temporary plan for tracker-backed delivery should not be stored permanently: after its requirements have been transferred to the relevant delivery tickets, remove the local artifact entirely.

## File-scoped agent directives (frontmatter)

A markdown doc can carry optional `agent:` frontmatter that agent tooling reads. All fields are optional; a doc without it behaves normally. This is general-purpose — pair any doc with any path it cares about. A directory README tracking its own files, a roadmap tracking `src/**` (flag shipped items for removal), a vision doc tracking `docs/plans/**` (re-read whenever plans change), a style guide tracking a lint config, are all equally valid uses.

Add this to docs you create if the instruction can be scoped to a path.

- `instruction` — a short directive re-surfaced whenever the file is read or edited (e.g. a roadmap's "remove items as they complete", a README's "update when this directory changes").
- `on-change` — a glob or list of globs; when a matching file is read or edited, this doc's instruction is surfaced, before the area gets worked blind. Throttled to once per doc per hour, not on every touch.
