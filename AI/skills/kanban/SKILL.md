---
name: kanban
description: Work with GitHub Projects, Milestones, and issue trackers. Use when you need to update delivery state, triage issues, create/update tickets/issues, organize milestones, or trace planned work.
model: sonnet
user-invocable: true
---

# Kanban

Check the GitHub remote for a Project board, Milestones, and issue tracker. If GitHub tracking is active, it is the operational source of truth for delivery state: Projects hold actual delivery work, Milestones hold delivery landmarks, and Issues hold bounded work items. Architecture and product documents remain linked context, not a parallel roadmap.

If a GitHub Project board does not exist, ask the user if they would like to create one using `gh`. Some projects may not need a dedicated board; record this as a project memory so you don't continue to ask.

Do not create a Project merely because GitHub Issues exists. For a small or intentionally untracked repository, follow its local planning convention and do not invent Milestones, Project items, or delivery tickets.

## Delivery record

For tracked work, choose one authoritative delivery record before implementation: the relevant issue by default, or a project item only when the repository uses project items as its declared work record. Keep the full slice-specific requirements, acceptance criteria, and completion evidence there.

An approved local plan is temporary working material, never a second source of truth. Transfer its details into the delivery record, then delete the file and any documentation references to it before implementation begins. If the repository does not use GitHub tracking, leave delivery-record selection to its local workflow; do not create tracker state to make this skill fit.

## Delivery hierarchy

- **Milestone**: a coherent delivery landmark with outcome, exclusions, exit criteria, scope-document links, and predecessor Milestone links. It is a container, not an issue or a task.
- **Project**: the execution surface. It holds real planning and implementation issues and uses the built-in Milestone field to group and filter them.
- **Issue**: one independently actionable unit of real work. It belongs to the relevant Project and Milestone once that work is planned or starts.
- **Parent/sub-issues**: optional grouping for real work within one planned feature slice. Never use them to emulate a Milestone hierarchy.

Use native issue blocking relationships for concrete prerequisites. Record landmark-level sequencing in the dependent Milestone's description. Do not create roadmap, epic, or placeholder issues solely to represent a Milestone.

## Setup

Create these labels if not already present.

Two category roles:

- `bug` — something is broken
- `enhancement` — new feature or improvement

Five state roles:

- `needs-triage` — maintainer needs to evaluate
- `needs-info` — waiting on reporter for more information
- `ready-for-agent` — fully specified and agent-owned; blocking relationships determine when it is takeable
- `ready-for-human` — fully specified and human-owned; blocking relationships determine when it is takeable
- `wontfix` — will not be actioned

Every triaged issue should carry exactly one category role and one state role. If state roles conflict, flag it and ask the maintainer before doing anything else.

Create these Project custom fields if not already present.

- `Start Date` — the date the issue was moved to `In Progress` status
- `End Date` — the date the issue was moved to `Done` status

## Synchronization

Before Milestone delivery work, inspect the active Milestone, its Project items, native blockers, parent context, linked pull requests, and relevant scope documents. For an isolated issue with no relevant Milestone, inspect its issue and Project context and record why it remains outside a delivery landmark when that would otherwise be ambiguous. When a tracked issue starts, assign its owner and set Project status to `In Progress`. When it completes, record acceptance evidence, close it, and set Project status to `Done`. For a stale or wrongly shaped item, leave a supersession note, close it, and remove it from the active Project rather than preserving misleading active state.

Update the issues `Start Date` and `End Date` fields when its status changes.

A planning issue is legitimate only when planning is the actual frontier. Once its approved plan is decomposed, the delivery tickets become the implementation authority: each owns the full detail relevant to its slice. Close the planning issue as completed planning work and remove a temporary local plan rather than leaving a duplicate specification. The planning issue is neither a parent epic nor an enduring requirements document.

Keep Project metadata meaningful: use Status, Milestone, Parent issue, Sub-issues progress, and Linked pull requests. Add iterations, priority, size, and status updates only when they express a real commitment or decision. Ensure the Project has useful views for current work, triage, ready/unblocked work, and completed work.

## Invocation

The maintainer invokes `$kanban` and describes what they want in natural language. Interpret the request type and act. Examples:

- "Show me anything that needs my attention"
- "Let's look at #42" (issue or PR)
- "Move #42 to ready-for-agent"
- "What's ready for agents to pick up?"

## Routing

Some request types require additional information; read the corresponding workflow completely before acting:

- Triage issues: [triage.md](triage.md)
- Turn actionable work from a plan, spec, or conversation into tickets: [to-tickets.md](to-tickets.md)
- Gathering current state and context for a feature: [trace-feature.md](trace-feature.md)

Load only the workflow required for the current request.
