# Planning

The order of operations should be:

1. Discuss the unit of work with the user
2. Planning decision:
   2a. If the task is straightforward and well-bounded: no planning necessary. Most tasks fall under this category. Spikes never require a plan. Always ask the user if you're not sure.
   2b. If the task is more complex: you must call a dedicated planning agent and have them create a HTML plan file. Use a planning agent when architecture, feature design, consequential trade-offs, or implementation sequencing need dedicated exploration.
3. Once the user agrees with the approach:
   3a. For projects with a board: turn any plan files into durable tickets on the project board. Remove the plan file once the transfer is complete
   3b. For projects without a board: keep plan files in the repo until they are complete
4. Implement the work
5. Local plan files can now be archived. Board tickets can be closed.

Planning can take a while. Check in with the planner subagent while it's working, but let it finish.

Once a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

## Plan storage

When a repository has both a GitHub remote and an existing GitHub Project board, use `$kanban` after the user approves a plan to convert it to tickets and track real delivery work. A planning issue is valid when planning is genuinely the next unit of work. Its plan file is temporary: after ticketization, the real delivery issues own the relevant implementation detail and the planning issue records that its work completed. The `kanban` skill owns the exact tracker handoff.

When a repository does not use a Project board, follow its local docs and archival conventions.
