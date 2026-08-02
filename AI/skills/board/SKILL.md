---
name: board
description: Work with the projects board and issue tracker. Use when you need to update tasks, triage issues, create tickets, track/locate plans.
model: sonnet
user-invocable: true
---

# Board

Check the GitHub remote for a Project board and issue tracker. If available, assume that is where bugs, requests, and tickets are stored.

If a GitHub Project board does not exist, ask the user if they would like to create one using `gh`. Some projects may not need a dedicated board; record this as a project memory so you don't continue to ask.

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

Wayfinder child tickets follow this invariant. A `wayfinder:map` issue is an index rather than a unit of work: give it one category role, but no state role.

## Invocation

The maintainer invokes `/board` and describes what they want in natural language. Interpret the request type and act. Examples:

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
