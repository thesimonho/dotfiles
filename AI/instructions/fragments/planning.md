# Planning

## Delivery record

Before implementation, choose exactly one durable delivery record. It owns the approved scope, decisions, acceptance criteria, and completion state.

Use this order:

1. The relevant issue, when the repository tracks work in issues.
2. The relevant project item, when the project board is the repository's declared delivery system.
3. A local roadmap or specification, when repository documentation declares it as the delivery record.
4. The pull request or commit, when the repository has no other delivery system.

Do not create a tracker, board, issue, or plan merely to satisfy this rule.
Follow the repository's existing delivery convention.

## Planning decision

Plan only when meaningful uncertainty remains: architecture choices, cross-cutting changes, migrations, consequential product trade-offs, or a multi-step delivery sequence. For straightforward, well-bounded work, implement directly. Spikes do not require a delivery plan.

For complex work, use a dedicated planning agent. It must produce an implementation-ready decision record; it may use a temporary local HTML plan while exploring.

## Workflow

1. Discuss the unit of work with the user.
2. Choose the delivery record and decide whether planning is needed.
3. When needed, plan the work and get user approval. This is the ideal time to use the `wayfinder` skill to nail down spec and requirements.
4. Transfer every approved implementation detail and acceptance check into the delivery record.
5. Delete any temporary planning artifact and remove references to it.
6. Implement the work.
7. Close or complete the delivery record according to the repository's workflow.

Planning can take a while. Check in with the planner subagent while it's working, but let it finish.

Once a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.
