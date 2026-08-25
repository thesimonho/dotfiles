# Triage

Move issues on the project issue tracker through a small state machine of triage roles.

State transitions: an unlabeled issue normally goes to `needs-triage` first; from there it moves to `needs-info`, `ready-for-agent`, `ready-for-human`, or `wontfix`. `needs-info` returns to `needs-triage` once the reporter replies. The maintainer can override at any time — flag transitions that look unusual and ask before proceeding.

## Show what needs attention

Query the issue tracker and present three buckets, oldest first:

1. **Unlabeled** — never triaged.
2. **`needs-triage`** — evaluation in progress.
3. **`needs-info` with reporter activity since the last triage notes** — needs re-evaluation.

Show counts and a one-line summary per item. Let the maintainer pick.

## Triage a specific issue

1. **Gather context.** Read the full issue or PR (body, comments, labels, author, dates; for a PR, the diff too). Parse any prior triage notes so you don't re-ask resolved questions. Use the `trace-feature` workflow to gather related tickets. Explore the codebase using the project's directory READMEs and docs. Run checks against the codebase: **redundancy** — search for an existing implementation of the requested behavior by domain concept (not just the request's wording), and report where you looked. If found, it's an already-implemented `wontfix` (step 5).

2. **Recommend.** Tell the maintainer your category and state recommendation with reasoning, plus a brief codebase summary relevant to the request — including whether it's already implemented. Wait for direction.

3. **Verify the claim.** Before using the `/grilling` skill, check that the claim holds up. For a bug, reproduce it from the reporter's steps. For a PR, confirm the diff does what it claims — check it out, run the relevant tests or commands. Report what happened: confirmed (with code path), failed, or insufficient detail (a strong `needs-info` signal). A confirmed verification makes a much stronger plan.

4. **Grill (if needed).** If the request needs fleshing out, run the `/grilling` skill — grill it into shape one question at a time. Apply `domain-modeling` as an overlay when domain terms or operations need clarification, and update the glossary as they are resolved.

5. **Apply the outcome:**
   - `ready-for-agent` — confirm the issue is independently actionable. If material implementation decisions remain unresolved, report the concrete gaps to the caller; otherwise a clear issue or spec may become ready without a dedicated plan.
   - `ready-for-human` — tasks that need human judgement/decisions and can't be delegated (judgment calls, external access, design decisions, manual testing).
   - `needs-info` — post triage notes (template below).
   - `wontfix` — close, with the comment depending on _why_:
     - **Already implemented** — the change already exists in the codebase. Point to where it lives;
   - `needs-triage` — apply the role. Optional comment if there's partial progress.

For accepted delivery work in a tracked repository, attach the issue to the appropriate existing Milestone and Project. Do not manufacture a new Milestone for an isolated maintenance fix; record why no delivery landmark applies when that would otherwise be ambiguous. Keep the Project status synchronized with the triage result.

### Needs-info template

```markdown
## Triage Notes

**What we've established so far:**

- point 1
- point 2

**What we still need (@reporter):**

- question 1
- question 2
```

Capture everything resolved during grilling under "established so far" so the work isn't lost. Questions must be specific and actionable, not "please provide more info".

## Resuming a previous session

If prior triage notes exist on the issue or PR, read them, check whether the reporter has answered any outstanding questions, and present an updated picture before continuing. Don't re-ask resolved questions.
