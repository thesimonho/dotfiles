---
name: wayfinder
description: Resolve dependent questions and decisions that prevent a confident implementation approach. Use when uncertainty spans more than one session and needs a shared decision map before planning or actionable work can proceed.
---

A loose idea has arrived wrapped in enough uncertainty that Frank cannot yet create a confident implementation plan. Wayfinding is about resolving that uncertainty, not planning or building the implementation. This skill charts a **shared map** on the repo's issue tracker, then works its **decision tickets** — questions whose resolution is a decision, not slices of a build to execute — one at a time until the route is clear.

The **destination** is the decision state Frank needs before implementation planning can proceed. Naming it is the first act of charting because it shapes every ticket and fixes the map's scope. The map is domain-agnostic — engineering work, course content, or anything else where dependent decisions obscure the route forward.

## Tracking boundary

When GitHub tracking exists, use its issue tracker for a Wayfinder map and decision tickets. They are planning artifacts, not delivery work. When the map resolves, hand off to `/board` for any tracked delivery work.

If a repository has no issue tracker or intentionally uses no Project, do not create one merely for Wayfinder. Keep the same destination, decision, and resolution structure in the active planning artifact and use the repository's local planning convention for the later handoff.

## Plan, don't do

Wayfinder is **pre-planning** by default. It resolves the questions that prevent a confident implementation approach. Each ticket resolves a decision, and the map is done when the way is clear — nothing left to decide before the invoking context can determine what happens next. The pull to write implementation steps is usually the signal you've reached the edge of the map and it is time to hand back the resolved decisions.

Prototype and task tickets may perform bounded work only when that work is necessary to resolve a decision. Do not carry feature implementation into the map.

Do not use `/board to-tickets` for decision tickets. That workflow publishes an approved implementation plan as actionable work after Frank finishes planning. Wayfinder creates and maintains its own map and decision tickets on the issue tracker.

Apply the `domain-modeling` skill as an overlay throughout Wayfinder whenever domain terms or operations are introduced, challenged, or resolved. Domain Modeling keeps the language consistent; Wayfinder owns the decisions.

## Refer by name

Every map and ticket is an issue, so it has a **name** — its title. In everything the human reads — narration, the map's Decisions-so-far — refer to it by that name, never by a bare id, number, or slug. A wall of `#42, #43, #44` is illegible; names read at a glance. The id and URL don't vanish — a name wraps its link — but they ride _inside_ the name, never stand in for it.

## The Map

When the repository has an issue tracker, the map is a single issue labelled `wayfinder:map` — the canonical artifact. Its tickets are child issues of the map. Without a tracker, the active planning artifact is the canonical map and the same separation of decision detail applies.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place — its ticket — so the map never restates it, only gists it and links.

### The map body

The whole map at low resolution, loaded once per session. Open tickets are **not** listed — they are open child issues, found by tracing the feature using the `/board` skill.

```markdown
## Destination

<the decision state that makes the implementation approach clear enough for the invoking context to proceed. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index — one line per closed ticket: enough to judge relevance, then zoom the link for the detail the ticket holds -->

- [<closed ticket title>](link) — <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't ticket yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is a **child issue** of the map; the tracker's issue id is its identity. Its body is the question, sized to one 100K token agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries a `wayfinder:<type>` label — one of `research`, `prototype`, `grilling`, `task` (see [Ticket Types](#ticket-types)).

Wayfinder decision tickets also use Board's normal labels. Apply the effort's `bug` or `enhancement` category to every child ticket, then apply exactly one state label:

- `needs-triage` when the ticket's driver or resolution mode still needs maintainer evaluation.
- `needs-info` when progress is waiting on information from the user or another person.
- `ready-for-agent` for an AFK ticket whose question is sufficiently specified. Blocking relationships, not the label, determine whether it is on the current frontier.
- `ready-for-human` for a sufficiently specified HITL ticket. Blocking relationships, not the label, determine whether it is on the current frontier.
- `wontfix` when the ticket is ruled out of scope.

The `wayfinder:map` issue is an index rather than a unit of work. Give it the effort's category label, but exempt it from Board's state-label invariant.

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work, so concurrent sessions skip it. That assignee _is_ the claim: an open, unassigned ticket is unclaimed.

Blocking uses the tracker's **native** dependency relationship — essential because it renders the frontier _visually_ in the tracker's own UI, so the human sees what's takeable without opening the map. A ticket is **unblocked** when every ticket blocking it is closed; the **frontier** is the open, unblocked, unclaimed children — the edge of the known.

The answer isn't part of the body — it's recorded on resolution (see [Work through the map](#work-through-the-map)). Assets created while resolving a ticket are linked from the issue, not pasted in.

## Ticket Types

Every ticket is either **HITL** — human in the loop, worked _with_ a human who speaks for themselves — or **AFK**, autonomously driven by the agent alone. A HITL ticket only resolves through that live exchange; the agent never stands in for the human's side of it (a grilling agent that answers its own questions has broken this).

- **Grilling** (HITL): Conversation via the `/grilling` skill, one question at a time. Apply `domain-modeling` throughout when domain language is involved. The default case.
- **Research** (AFK): Reading documentation, third-party APIs, or local resources like knowledge bases to surface a fact a decision waits on. Resolved by using the `/deep-research` skill. Use when knowledge outside the current working directory is required.
- **Prototype** (HITL): Raise the fidelity of the discussion by making a cheap, rough, concrete artifact to react to — an outline, a rough take, a stub, or UI/logic code. Use when "how should it look" or "how should it behave" is the key question.
- **Task** (HITL or AFK): Manual work that must happen before a _decision_ can be made — nothing to decide, prototype, or research, but the next step is blocked until it's done. This is the one type that _does_ rather than decides — and it earns its place by unblocking the path. The agent drives it alone where it can (AFK); otherwise it hands the human a precise checklist (HITL). Resolved when the work is done; the answer records what was done and any resulting facts (credentials location, new URLs, row counts) later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete: don't chart what you can't yet see. Beyond the live tickets lies the **fog of war** — the dim view of decisions and investigations you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets — one at a time, until the way to the destination is clear and no tickets remain.

The map's **Not yet specified** section is where that dim view is written down: the suspected question, the area to revisit later. It's the undiscovered frontier _toward_ the destination — everything here is in scope, just not sharp enough to ticket. Write as loosely or as fully as the view allows; it doubles as a signpost for collaborators reading where the effort is headed.

**Fog or ticket?** The test is whether you can state the question precisely now — _not_ whether you can answer it now.

- **Ticket when** the question is already sharp — even if it's blocked and you can't act on it yet.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog into ticket-sized pieces: it's coarser than a ticket, and one patch may graduate into several tickets, or none, once the frontier reaches it.

**Not yet specified** excludes what's already decided (Decisions so far), what's already a live ticket, and what's out of scope (the next section).

## Out of scope

Fog only ever gathers _toward_ the destination. The destination fixes the scope, so work beyond it is **out of scope** — it isn't fog, and it doesn't belong in **Not yet specified**. It gets its own **Out of scope** section on the map: work you've consciously ruled out of _this_ effort. Scope, not sharpness, lands it here.

Out-of-scope work never graduates — the frontier stops at the destination — so it returns only if the destination is redrawn, and then as a fresh effort, not a resumption.

Ruling something out of scope is a scoping act, not a step on the route. When a ticket that already exists turns out to sit past the destination — mis-scoped in while charting, or exposed by a resolution — **close it** (a closed ticket is unambiguously off the frontier) and leave one line in the **Out of scope** section: the gist plus why it's out of scope, linking the closed ticket. It stays out of **Decisions so far**, which records the route actually walked — a scope boundary isn't a step on it.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session** — with the exception of research tickets.

### Chart the map

The user or an orchestrating agent invokes Wayfinder with a loose idea.

1. **Name the destination.** Run a `/grilling` session to pin down what this map is finding its way to — the spec, feature, or change. Apply `domain-modeling` as an overlay whenever domain language is involved. The destination fixes the scope, so it's settled first.
2. **Map the frontier.** Grill again, **breadth-first** this time: fan out across the whole space rather than deep on any one thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog** — the way to the destination is already clear — do not create a map. Return the clarified context to the invoker, which may proceed inline, send actionable work to Board, or invoke Frank if dedicated implementation planning is still useful.
3. **Create the map** (label `wayfinder:map`) when a tracker exists: Destination and Notes filled in, Decisions-so-far empty, the fog sketched into **Not yet specified**. Without a tracker, create the equivalent active planning artifact instead.
4. **Create the tickets you can specify now** as child issues of the map when a tracker exists — then wire blocking edges in a **second pass** (issues need ids before they can reference each other). Without a tracker, retain the same ordered decision list in the planning artifact. Everything you can't yet specify stays in the fog — the **Not yet specified** section.
5. **Fire the research subagents.** For each unblocked `research` ticket on the frontier, launch one isolated subagent. Each subagent claims and resolves only its assigned ticket using the `deep-research` skill, posts its resolution, and closes the ticket. The charting session collects those resolutions and updates the map; it does not resolve any HITL ticket.
6. Stop — charting is one session's work beyond the isolated research resolutions.

### Work through the map

The user or an orchestrating agent invokes Wayfinder with a map (URL or number). A ticket is **optional** — without one, you pick the next decision, not the user.

1. Load the **map** — the low-res view, not every ticket body.
2. Choose the ticket. If the user named one, use it. Otherwise take the first frontier ticket in order. **Claim it**: assign it to yourself before any work.
3. Resolve it — **zoom as needed**: fetch the full body of any related or closed ticket on demand. If in doubt, use `/grilling`; apply `domain-modeling` as an overlay when domain language is involved.
4. Record the resolution: post the answer as a **resolution comment**, **close** the issue, and **append a context pointer** to the map's Decisions-so-far.
5. Add newly-surfaced tickets (create-then-wire); graduate any fog the answer has made specifiable, clearing each graduated patch from **Not yet specified** so it lives only as its new ticket. If the answer reveals a ticket — this one or another — sits beyond the destination, **rule it out of scope** rather than resolving it on the route. If the decision invalidates other parts of the map, update or delete those tickets.
6. Recompute the frontier and inspect **Not yet specified**. If no open child tickets and no in-scope fog remain, mark the map complete and return its resolved decisions to the invoking context. Invoke Frank when consequential implementation planning is still needed; otherwise proceed inline or hand tracked delivery work to `/board`. In an untracked repository, follow its local planning convention instead.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker concurrently.
