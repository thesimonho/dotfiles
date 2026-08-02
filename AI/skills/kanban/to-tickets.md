# To Tickets

Break actionable work from a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

Not all actionable work needs a dedicated implementation plan. Preserve a clear, sufficiently specified request and publish it directly. If producing independent tickets would require consequential unresolved architecture, product, or implementation decisions, stop and route that planning work to Frank. Kanban represents actionable work on the tracker; it does not silently make the decisions that would make the work actionable. Do not use Frank for simple, already bounded work.

Critical: each ticket must be independently actionable by a new agent after reading that ticket and its explicitly linked parent context. Sibling or child tickets may explain sequencing, but must not contain requirements needed to implement this ticket.

When the source is an approved dedicated plan, ticketization is a **lossless handoff**, not a summary. Move every slice-specific decision into the relevant ticket body: user outcome, architecture constraints, concrete locations, implementation steps, edge cases, acceptance evidence, and local risks. A ticket may link the closed planning issue as provenance, but it must not depend on an external plan file or issue for requirements needed to implement it. The temporary plan ceases to be an active specification after handoff.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments. When the work advances a tracked delivery landmark, first identify its active Milestone and inspect existing Project work so the new tickets extend the delivery graph rather than duplicating it. For isolated maintenance work with no relevant landmark, inspect the related Project and issue context instead.

Before drafting, confirm the source defines an observable outcome, sufficient acceptance criteria, and no unresolved decisions that would materially change the implementation. Route it to Frank only when dedicated implementation planning is needed; otherwise continue directly.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Apply the `domain-modeling` skill as an overlay while drafting so ticket titles, domain operations, and descriptions remain consistent with the project's `docs/glossary.md`, approved plan, and codebase.

Preserve prefactoring already established by the source. If new prefactoring would require an implementation decision, route that decision to Frank rather than inventing it during ticketization.

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change — rename a column, retype a shared symbol — whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

### 4. Confirm the delivery container

When GitHub tracking exists, assign the ticket set to the active Milestone. If the work begins a new coherent landmark, create or have the maintainer create a Milestone first; do not create an epic issue as a substitute. A planning ticket is valid only when planning is actual next work, not as a placeholder for an unstarted landmark.

### 5. Quiz the user

Present the proposed full ticket bodies as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **Implementation context**: the complete slice-specific plan an implementing agent needs
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 6. Publish the tickets to the configured tracker

Publish one issue per ticket in dependency order (blockers first) so each ticket's blocking edges can reference real identifiers. Add every tracked ticket to the Project and active Milestone. Use the platform's native blocking / sub-issue relationship where it has one; otherwise set each ticket's "Blocked by" to the blocking issues. Parent/sub-issues may group actual feature-slice work but must not represent the Milestone itself.

When a planning issue produced the approved plan, close it after publication with a concise handoff comment that lists the replacement tickets. Remove any temporary local plan only after confirming every slice-specific requirement now lives in its ticket body. Do not leave a plan file or planning issue as a second implementation source of truth.

When publishing issue bodies, preserve actual newline characters. Prefer `--body-file` or structured API input; never interpolate a JSON-stringified body into `gh issue create --body`.

Apply the `ready-for-agent` triage label unless instructed otherwise — the tickets are agent-grabbable by construction. Set Project status to `Todo`; the assignee and `In Progress` status are the claim when work begins.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

<issue-template>
## Parent

A reference to the parent issue on the tracker (if the source was an existing issue, otherwise omit this section).

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not layer-by-layer implementation.

## Implementation context

The full portion of the approved plan relevant to this slice: constraints, code locations, implementation steps, edge cases, and any local verification details.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None — can start immediately".
</issue-template>
