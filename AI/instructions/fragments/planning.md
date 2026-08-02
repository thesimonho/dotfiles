# Planning

For consequential multi-file changes, create and review a plan first. Use Frank when architecture, design, trade-offs, or implementation sequencing need dedicated exploration; plan simple, well-bounded work directly. Escalate to a stronger model when the decision complexity warrants it.

When a repository has both a GitHub remote and an existing GitHub Project board, use `$kanban` after the user approves a plan to publish and track real delivery work. A planning issue is valid when planning is genuinely the next unit of work. Its plan is temporary: after ticketization, the real delivery issues own the relevant implementation detail and the planning issue records that its work completed. The Kanban workflow owns the exact tracker handoff. For every other repository, follow its local planning convention; plan file names should start with a date and time stamp YYYYMMDD, eg `20231201-<name>.md`.

If a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

Do _NOT_ reference plan files in code comments, rules files, or docs/ reference files.

Use Todo/Task list while working through it.

You must think through your decisions and recommendations. It's very easy to recommend a path and not realize there's a blocker until half way through implementation. You must think ahead and catch this during the planning phase.

If bringing in external libraries, you must first do a web search for the latest version, and check whether the dependency you want is the latest best practice for the ecosystem.

## Untracked local HTML plans

Use a local plan under `docs/plans/` only for untracked work or durable repository documentation. Do not retain it as a duplicate implementation specification after a tracked plan has been decomposed into delivery tickets. When creating one, write a single self-contained `.html` file (inline CSS, no external assets).

Keep the HTML structure as simple as possible and well spaced. Don't use `<div>` `<span>` `<p>` tags unless you _need_ to.

Structure:

- **TL;DR header** with summary/overview.
- **Numbered sections** (`01`, `02`, …) — readers cite them as anchors.

Always use visual components to aid comprehension. Examples:

- **Tables** for risks, trade-offs, decision matrices, content-to-structure mappings.
- **Accordions** for collapsible sections. Sections that refer to completed/resolved work should be collapsed by default.
- **Tabs** for different phases/major sections.
- **Side-by-side blocks** for before/after, request/response, option1/option2.
- **Mermaid diagrams** for paths, data flow, architecture. Caption them; label edges.
- **Callouts** for trust boundaries, gotchas, open questions — visually distinct from prose.
- **Chips** (`HIGH`, `MED`, `LOW`, `Completed`) as inline spans, not prose.
- **Code blocks** with the file path as a header and `file:line` references back to source.
