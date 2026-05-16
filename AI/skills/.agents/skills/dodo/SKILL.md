---
name: dodo
description: Use proactively to create and update project documentation. Manages codemaps (for agents), references (for contributors), documentation sites (for users), and plugin/skills scaffolding (for agent users and developers). Run with no arguments to update everything, or specify a documentation type to update. Users may invoke this as "/dodo", "dodo", "dodocs", "update the docs", "generate a codemap", "update the reference docs", or similar phrasing — trigger this skill whenever the user's intent is to create or update project documentation.
argument-hint: "[codemaps, references, site, plugin]"
---

The fundamental principle of dodo and this skill: different audiences need different types of documentation. The documentation types below are designed to target drastically different demographics. Above all, you must first consider what type of audience you are writing for and what their specific needs are. If any 2 documentation types start overlapping in content, focus, or level of detail, then you are doing it wrong.

## Interpreting arguments

Parse `$ARGUMENTS` to determine which documentation type(s) to work on:

- **No argument** (empty): update all types in priority order
- **Type keyword**: `codemaps`, `references`, `site`, `plugin` — work on that type only
- **Multiple types**: "codemaps and references", "site and plugin" — work on the listed types
- **"all" or "everything"**: update all types in priority order
- **Freeform text**: interpret the user's intent and route to the correct type. Examples:
  - "the site FAQ" → site type, specifically the FAQ page
  - "add a codemap for the auth module" → codemaps type, specifically create/update for auth
  - "update the deployment guide" → references type, specifically the deployment guide
  - "fix the broken link on the getting started page" → site type, specific page

If the intent is ambiguous, ask the user to clarify before proceeding.

## Finding documentation

Each documentation type has a default location. Check the default first.

| Type       | Default location |
| ---------- | ---------------- |
| Codemaps   | `docs/codemaps/` |
| References | `docs/`          |
| Site       | `docs/site/`     |
| Plugin     | `docs/plugin/`   |

If documentation isn't at the default location:

1. Check agent memory for previously stored locations (the `dodo:find` agent stores these).
2. If not in memory, dispatch the `dodo:find` agent to search the codebase. It will store the locations in memory for future invocations.
3. If the find agent reports "not found" for a type, that type doesn't exist yet — proceed to the create flow.

## Preparing data

To make the update process faster, get a list of changed files for the commit/branch/feature you want to update.
If the user asks for a general update, you will need a change list for the last 10 commits across the entire project instead.

Pass this along to the agent doing the documentation update, along with a description of the changes and summary of the relevant conversation history.

This will help the agent know which files to examine for changes.

## Create vs update

For each requested documentation type, follow this sequential fallback:

1. **Find it.** Use the search strategy above.
2. **If found → update.** Read the type's reference file (linked below) and follow its update flow.
3. **If not found → ask.** Tell the user: "I don't see {type} documentation for this project. Would you like me to create it?"
4. **If the user says yes → create.** Read the type's reference file and follow its create flow.
5. **If the user says no → skip.** Move to the next type.

When updating documentation, make sure to verify all mentioned files exist and fix any broken links.

Never create documentation without asking first. The user may not want or need every type.

## Priority order

When working on multiple types, process them in this order:

1. **Codemaps** — foundational. Other documentation types benefit from codemaps existing.
2. **References** — high-value for contributors. Catches stale content before it misleads anyone.
3. **Site** — user-facing. Important but less likely to cause harm if slightly outdated.
4. **Plugin** — meta-documentation. Only relevant if the project distributes skills/agents.

This ordering matters for two reasons:

- If the session is interrupted or context runs low, the most foundational work is already done.
- Codemaps created in step 1 inform the work in later steps (e.g., the site can reference the codemap structure).

## Parallel execution

When updating 2 or more types, use subagents to divide the work:

- Dispatch one subagent per documentation type.
- Each subagent should read the relevant reference file for its instructions.
- Priority order determines dispatch sequence — codemaps first, then references, then site, then plugin.
- After all subagents complete, summarize what was created or updated across all types.
- **Model defaults**: Use `model: "haiku"` for codemaps subagents. Use `model: "sonnet"` for all other subagents (references, site, plugin). The user may override these per invocation.

For single-type requests, work directly without subagents.

## Summary and Feedback

After you have finished updating all types, inform the user of what was created or updated.

Then create a project memory noting which documentation types and which project areas lagged behind and went stale.

Check in on the memory periodically to see if specific areas are frequently lagging behind and let the user know. Brainstorm a solution with them to help them stay on top of updates. After coming up with and implementing a solution, you can reset your memory counts and start again from 0.

If you had to update a large amount of documentation, across multiple files, ask the user if they want to use the /loop command to periodically run a documentation update.

## Reference files

These files contain detailed instructions for each documentation type — structure specifications, content templates, create flows, update flows, and quality rules.

- [Codemaps](./codemaps.md) — structured codebase maps for AI agent navigation
- [References](./references.md) — contributor-facing documentation, guides, and plans
- [Site](./site.md) — public documentation website deployed to GitHub Pages
- [Plugin](./plugin.md) — Claude Code plugin and Vercel npx skills scaffolding
