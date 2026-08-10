# Planning

If the task is straightforward and well-bounded: no planning necessary; you can go straight to implementation.

If the task is more complex: you must call a dedicated planning agent and have them create a HTML plan file. Use a planning agent when architecture, design, trade-offs, or implementation sequencing need dedicated exploration.

Once a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

## Plan storage

When a repository has both a GitHub remote and an existing GitHub Project board, use `$kanban` after the user approves a plan to convert it to tickets and track real delivery work. A planning issue is valid when planning is genuinely the next unit of work. Its plan is temporary: after ticketization, the real delivery issues own the relevant implementation detail and the planning issue records that its work completed. The `kanban` skill owns the exact tracker handoff.

When a repository does not use a Project board, follow its local docs and planning conventions.
