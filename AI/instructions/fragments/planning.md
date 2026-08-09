# Planning

For large multi-file changes, create and review a plan first. Use a planning agent when architecture, design, trade-offs, or implementation sequencing need dedicated exploration; plan simple, well-bounded work directly. Escalate to a stronger agent model when the decision complexity warrants it.

Plans must be detailed enough that a different agent can fully implement the work with no prior knowledge. As a result, you must think through your decisions and recommendations. It's very easy to recommend a path and not realize there's a blocker until half way through implementation. You must think ahead and catch this during the planning phase.

Once a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

## Task Manager Type

When a repository has both a GitHub remote and an existing GitHub Project board, use `$kanban` after the user approves a plan to publish and track real delivery work. A planning issue is valid when planning is genuinely the next unit of work. Its plan is temporary: after ticketization, the real delivery issues own the relevant implementation detail and the planning issue records that its work completed. The Kanban skill owns the exact tracker handoff.

When a repository does not use a Project board, follow its local planning convention; plan file names should start with a date and time stamp YYYYMMDD, eg `20231201-<name>.md`.

## Untracked local HTML plans

Use a local plan under `docs/plans/` only for untracked work or durable repository documentation. Do not retain it as a duplicate implementation specification after a tracked plan has been decomposed into delivery tickets.

When creating a local plan, write a single self-contained `.html` file (inline CSS, no external assets).

Keep the HTML structure as simple as possible and well spaced. Don't use `<div>` `<span>` `<p>` tags unless you _need_ to. Always use visual components to aid comprehension. Examples:

- **Tables** for risks, trade-offs, decision matrices, content-to-structure mappings.
- **Accordions** for collapsible sections. Sections that refer to completed/resolved work should be collapsed by default.
- **Tabs** for different phases/major sections.
- **Side-by-side blocks** for before/after, request/response, option1/option2.
- **Mermaid diagrams** for paths, data flow, architecture. Caption them; label edges.
- **Callouts** for trust boundaries, gotchas, open questions — visually distinct from prose.
- **Chips** (`HIGH`, `MED`, `LOW`, `Completed`) as inline spans, not prose.
- **Code blocks** with the file path as a header and `file:line` references back to source.
