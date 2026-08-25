# Planning

Keep these records distinct: a **working outline** is disposable execution scaffolding; a **decision map** resolves dependent uncertainty; an **implementation plan** settles the material decisions another agent needs to build the work; and a **delivery record** is the project-native authority for implementation and completion.

The running agent owns transitions between records. Skills and subagents produce only the artifact requested; they do not choose the next workflow.

## Delivery record

Before implementation, choose exactly one durable delivery record in this order:

1. The relevant issue, when the repository tracks work in issues.
2. The relevant project item, when the project board is the repository's declared delivery system.
3. A local plan, roadmap, or specification when that is the repository convention.
4. The pull request or commit when no other delivery system exists.

Do not create tracking machinery merely to satisfy this rule. Delete a temporary artifact only after transferring its approved details; retain a local plan when it is the delivery record.

## Planning decision

Inspect what is already known before planning. A `ready-for-agent` ticket is presumed implementation-ready unless a specific material gap or contradiction is found. Complexity alone does not justify replanning it.

Handle bounded detail directly. Use the planning agent when unresolved product, architecture, or implementation decisions require substantial exploration or judgment. Use Wayfinder skill only when dependent uncertainty needs a shared, multi-session decision map.

A working outline becomes authoritative only when deliberately promoted into the delivery record after it defines the outcome, material decisions, affected boundaries, failure behaviour, acceptance checks, dependencies, and non-goals. If an allegedly ready record fails that test, report the concrete gaps and return it to planning or triage; do not create a parallel plan.

## Workflow

Agree on scope, resolve uncertainty, obtain approval when required, and select the project-native delivery record. In tracked projects, approved material may be decomposed into independently actionable tickets. In untracked projects, the approved local plan may remain authoritative. Implement and record completion against that one delivery record.

Once an approved plan is established, do not deviate without pausing to discuss the change.
