---
name: deep-research
description: Conduct rigorous, citation-backed research on a question, then deliver a self-contained HTML report that ends in a clear recommendation. Use this whenever the user asks you to "research", "do a web search", "do a deep dive", "compare options", or asks any question that needs evidence from multiple current sources rather than a single lookup. Use it even when the user doesn't say "research" — if answering well means pulling together several online sources, cross-checking them, and citing them, use this. Do NOT use it for single-fact lookups answerable from one source.
argument-hint: "topic, light or full research. Optional: time limit, HTML output"
model: opus
user-invocable: true
---

# Deep Research

A workflow for turning an open question into an evidence-backed, citation-checked HTML report — on a time budget, ending in a recommendation.

## Assumed capabilities

Assumes **parallel subagents**, a **filesystem**, a **fetch tool**, and **bash** (`date`, `curl`). Use all of them.

### Bundled scripts

Two portable bash helpers live in this skill's `scripts/` (no harness dependency):

- `clock.sh` — time-budget tracker (`start` / `log` / `check` / `elapsed` / `end`).
- `verify-links.sh` — citation-integrity verifier (enforces rule 2, checks liveness).

**Invocation:** stay in your **project working directory** (the scripts read and write `./docs/deep-research/`), but call the scripts by their **absolute path inside this skill**. Capture it once:

```bash
SKILL_DIR="<the directory this SKILL.md was loaded from>"
"$SKILL_DIR/scripts/clock.sh" start 600
```

Override the workspace location with `RESEARCH_DIR` if you run from elsewhere.

## The two rules everything else serves

1. **Draft from notes, not open tabs.** Extract what matters from fetched pages into notes on disk (all interim files are markdown kept in the `.tmp/` scratch directory), then write from the notes. Every claim traces to a named source.
2. **Only cite a page you actually fetched and took notes from** — never a search snippet or a URL from memory. `verify-links.sh` enforces this: any cited URL missing from your notes is flagged `UNSOURCED`.

## Light vs. full

Pick one at the start; state which.

- **Light** — answer written **inline in the conversation**, no file. Gather directly (fan out only if the question splits into independent parts). For conversational asks, medium complexity, or tight budgets.
- **Full** — short **chat summary + self-contained HTML report**. Fan out subagents in parallel. For reports, deep dives, documents, or formal deliverables.

Default to **light** unless the user asks for a document or the question is clearly substantial; if unsure, ask. Both modes run every phase and **must end in a recommendation**.

## Model tiers for sub-roles

Match the **capability tier** — a bigger model, or higher reasoning effort on the same model, not a vendor's model name:

- **Light** (Claude Haiku; Codex 5.3 Spark) — mechanical work only. **Never gather with it** — thin notes poison synthesis.
- **Mid** (Claude Sonnet; Codex latest at medium effort) — the **gather subagents** (Phase 2). Fetch / comprehend / note is a mid-tier job; the frontier model on every gatherer is overkill.
- **Frontier** (Claude Opus; Codex latest at high effort) — the **orchestrator** (Phases 3–4) and the **red-team** lenses (Phase 5). Don't downgrade the judgment.

The gates (`clock.sh`, `verify-links.sh`) use no model at all.

## Time budget

If the user gave a budget, use it; otherwise default 10 min (light) / 20 min (full).

Start the clock first. `clock.sh start` creates `docs/deep-research/` and its `.tmp/` scratch dir, **clears the previous run's notes** (everything under `.tmp/`, at both start and end, so a crash can't leak), and drops a `.gitignore` that excludes `.tmp/` so only the HTML report(s) are committable — prior reports survive.

```bash
"$SKILL_DIR/scripts/clock.sh" start 600                    # seconds; light 600, full 1200
"$SKILL_DIR/scripts/clock.sh" log "dispatched 3 subagents" # trail of where time went
"$SKILL_DIR/scripts/clock.sh" check                        # -> elapsed 480s / budget 600s (80%) -> STOP GATHERING
```

Check **between gather rounds** and treat the printed verdict as an instruction — don't self-estimate elapsed time. Thresholds: **≥80% → stop and synthesize; ≥50% → prioritize what's left; else continue.** Never blow past the budget for one more source. Give each subagent its own soft limit ("~3 min, then return notes"). The report states actual elapsed time and flags anything the budget cut short.

## Phase 0 — Scope

1. Restate **the actual question** in your own words. If ambiguous in a way that changes the research, ask ONE clarifying question; else state your interpretation and proceed.
2. Define **what "done" looks like** — the sub-questions that fully answer the request.
3. Note the **as-of date** (today).
4. **Persist the verbatim question** to `docs/deep-research/.tmp/query.md`. This is the anchor: hand it to every subagent (told to re-read before returning) and re-read it before synthesizing — the cheapest defense against parallel subagents drifting from the ask.

## Phase 1 — Plan

Decompose into 3–7 sub-questions (scale to budget — a 5-minute job gets 2–3). For each, note what kind of source would settle it (primary data, official docs, peer review, named expert, first-hand reporting — not a blog summarizing those) and a first search angle.

## Phase 2 — Gather

Dispatch **one subagent per sub-question, in parallel**, each handed `.tmp/query.md` (re-read before returning). Each subagent:

1. Searches broad (1–3 words), then narrows with specifics.
2. For scholarly/technical/medical questions, **queries citation-ranked APIs before web search** (they return primary work, not derivative commentary): Semantic Scholar (`api.semanticscholar.org/graph/v1/paper/search`), arXiv (`export.arxiv.org/api/query`), OpenAlex (`api.openalex.org/works`), PubMed (`eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi`).
3. **Fetches the primary source** for anything that matters — snippets are too thin to cite.
4. Writes rich notes to `docs/deep-research/.tmp/<subquestion>.md` (the `.tmp/` scratch dir keeps the WIP collection uncommitted and separate from the report): the claim **and its evidence** (figures, versions, dates, the caveat that flips a verdict, a short quote where wording matters), plus source (title + URL), as-of date, one line on credibility. Capture too much — this file is the report's raw material, and the report can only be as detailed as its notes.
5. Returns a brief headline summary **plus the notes-file path** — not raw pages. This keeps the gather-phase context clean without discarding the detail synthesis needs.
6. Stops when new sources stop changing the answer, or its limit hits.

**Stay ecosystem-neutral.** When the question spans multiple vendors, tools, or ecosystems, don't over-weight whichever one publishes the most prescriptive guidance — the loudest documentation isn't the standard. Actively check how _other_ ecosystems solve the same problem, and flag any "best practice" that's really just one vendor's convention.

Log and check the budget after each round.

## Phase 3 — Triangulate

Working from notes, not the web:

- **Cross-check.** Two independent sources = solid; one = provisional, flag it as single-sourced.
- **Watch for false independence** — five articles citing one press release is one source. Likewise **subagent agreement counts only if they used different sources**: converging on a shared origin is still single-sourced. Vote on the evidence, not the agent count.
- **Resolve conflicts explicitly** — don't average; pick the more authoritative/recent and say why, or report the split.
- **Check recency** on anything that moves.

## Phase 4 — Synthesize

**Draft from the full note files — open and read every `docs/deep-research/.tmp/*.md` first.** The return messages were headlines; the substance (figures, versions, gotchas, per-option detail) lives in the files. Synthesis reorganizes and analyzes that evidence around the decision — drafting from memory is the biggest cause of a thin report.

**Preserve the decision-relevant specifics** — the numbers, versions, and verdict-flipping caveats. A report is better _organized_ than the notes, not thinner in substance; if a specific would change the reader's decision, it belongs in the report.

Structure around the user's decision, not the order you found things. Source every significant claim. Mark confidence honestly ("well-established" / "one source suggests" / "inferred") — no invented precision, no fake credibility scores.

**Always land on a recommendation** — even when the question wasn't framed as a choice. If the evidence won't support one, say so and recommend the best way to resolve the uncertainty. "It depends" is not a conclusion; "X because Y — unless Z, then W" is.

## Phase 5 — Counter-review (red-team)

Attack your draft through five lenses (parallel subagents in full mode; yourself in light):

- **Dialectic** — the strongest case _against_ the recommendation. Did you search for it as hard as for support? If not, do so now.
- **Depth** — which claims rest on a single/weak source or assumption? Label or substantiate them.
- **Breadth** — what expected angle is missing? Name the gap even if the budget won't fill it.
- **Fidelity** — diff the notes against the draft: did a decision-relevant specific get compressed out? If the report is a fraction of the notes' size, you summarized instead of synthesizing — restore it.
- **Instruction-adherence** — re-read `.tmp/query.md`. Does the draft answer _that_ question?

**Patch, don't regenerate** — targeted edits to the passages at fault; a full rewrite drops the good parts and reintroduces fixed errors. If something can't be fixed locally, surface it in Caveats. Don't skip this phase.

## Phase 6 — Verify citations

```bash
"$SKILL_DIR/scripts/verify-links.sh" --report docs/deep-research/<task-slug>.html  # full mode
"$SKILL_DIR/scripts/verify-links.sh"                                               # light mode (checks notes)
```

A non-zero exit is a **gate — fix before delivering**. Flags:

- **`UNSOURCED`** — cited but not in notes (probable fabrication or misremembered URL). Verify against a note or remove. (Full mode only.)
- **`BROKEN`** (`404` / `ERR`) — fix the URL or drop the claim.
- **`BOT-BLOCK`** (`403` / `405` / `429`) — usually a live page; manual look, doesn't fail the gate.

Add `--json` for a machine summary for the footer.

## Output

**Light — inline:** recommendation → findings with inline source links → caveats → short numbered source list → as-of date + elapsed (`clock.sh elapsed`). No file.

**Full — chat summary + HTML file:** post a 3–5 sentence summary (recommendation first), then write the report to `docs/deep-research/<task-slug>.html` — a **task-relevant kebab-case name** (e.g. `auth-provider-comparison.html`). Descriptive names keep committed reports self-documenting and stop a new run clobbering an old one. One file, inline CSS, no external deps. Structure:

1. **Recommendation** — first on the page; the answer/choice/next step in 2–4 sentences with stated confidence. Mandatory, never omitted.
2. **Findings** — the substance, and where detail lives. One developed section per sub-question, backed by the _specific_ evidence (real figures, versions, gotchas — not a paraphrase that drops the numbers), with the tradeoff made explicit. Analysis, not one-line verdicts. For "compare options" questions, include a **master comparison table** (options as columns, decision dimensions as rows, real values) _and_ per-option prose for the nuance a table can't hold.
3. **Caveats & open questions** — what's uncertain, contested, single-sourced, or unreached within budget.
4. **Sources** — numbered: title, publisher, URL, date.
5. **Methodology footer** — as-of date, elapsed (`clock.sh elapsed`), source count, link-check flags (`verify-links.sh --report <file> --json`).

A tight recommendation never licenses thin findings: in full mode the verdict is short _because_ the detailed evidence sits right below it.

## After delivery

Keep the thread open: invite the user to drill into a citation, expand a section, or challenge a claim — and offer to do it. If the research was meant to be acted on, name the obvious next action and offer to take it. Then close out (run **last** — it removes `.clock`):

```bash
"$SKILL_DIR/scripts/clock.sh" end   # clears notes + clock state; keeps the report and timing.log
```
