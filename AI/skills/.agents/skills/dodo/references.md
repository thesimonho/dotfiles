# References

Default model: `sonnet` — when dispatched as a subagent, use `model: "sonnet"` unless the user specifies otherwise.

Default directory: `docs/`

References are contributor-facing documentation — architecture decisions, development guides, project plans, working notes, and anything else that helps humans understand and contribute to the project. They capture knowledge that isn't derivable from reading the code alone.

## What counts as a reference

References vary massively by project and personal preference. Common types include:

- **Architecture decision records (ADRs)** — why a technical decision was made
- **Development guides** — how to set up, build, test, deploy
- **Project plans and roadmaps** — what's being built and why
- **TODO lists** — tracked work items and priorities
- **Internal specs** — API contracts, data models, protocol definitions
- **Troubleshooting guides** — known issues and their solutions
- **Runbooks** — operational procedures for services

## Structure conventions

References are inherently freeform — don't enforce rigid structure. But follow these conventions:

- **Index file**: maintain a `docs/README.md` that links to all reference docs with a one-line description of each
- **Grouping**: when there are 5+ docs of the same type, group them in a subdirectory (e.g., `docs/adrs/`, `docs/guides/`)
- **Location**: keep references in `docs/` unless the project has an established convention elsewhere. Root-level files like `CONTRIBUTING.md` stay at the root — that's standard.

## Create flow

Reference creation is user-directed. These are the user's notes and plans — don't generate content they haven't asked for.

1. Ask the user what kind of reference documentation would be most valuable for their project. Don't assume — a library needs API docs, a service needs runbooks, a monorepo needs an architecture overview.
2. Analyze the project and suggest 3-5 specific reference docs based on what you observe:
   - Has a `Dockerfile` or `docker-compose.yml`? Suggest a deployment guide.
   - Has a complex test setup? Suggest a testing guide.
   - Has multiple services or packages? Suggest an architecture overview.
   - Has environment variables? Suggest a configuration reference.
   - Has CI/CD workflows? Suggest a development workflow guide.
   - Has database migrations? Suggest a data model reference.
3. For each doc the user approves:
   - Draft an outline first (section headings and bullet points)
   - Get feedback on the outline
   - Write the full content only after approval
4. Create a `docs/README.md` index linking to all reference docs.
5. Never generate reference docs the user hasn't explicitly approved. Suggesting is fine. Creating unprompted is not.

## Update flow

Keeping references fresh is the single most important thing this documentation type does. Stale docs are actively harmful — they mislead contributors and erode trust in all documentation.

Important: if you're searching or reading documents, it's much faster to do it in parallel.

1. Read all existing reference docs in the documentation directory.
2. Cross-reference each doc against the current codebase state. Check for:
   - **Dead file paths**: do paths mentioned in docs still exist? Use Glob to verify.
   - **Outdated code examples**: do snippets in docs match current implementation? Read the source files and compare.
   - **Stale architecture descriptions**: does the described structure match the actual project layout?
   - **Completed TODOs**: are TODO items or roadmap items that have been finished still listed as pending?
   - **Version drift**: are version numbers, dependency names, or API endpoints current?
   - **Missing coverage**: have new major features been added that have no documentation at all?
3. Categorize findings:
   - **Factual inaccuracies** (wrong paths, outdated APIs, incorrect examples): fix these directly. These are objective errors.
   - **Stale opinions or plans** (outdated roadmaps, superseded decisions): flag these to the user with specific line references. Don't rewrite someone else's plans.
   - **Missing documentation** (new features with no docs): suggest new reference docs to the user. Follow the create flow if they approve.
4. Update the `docs/README.md` index if docs have been added, removed, or renamed.

## Principles

- **References are the user's documentation, not yours.** Respect their voice, structure, and decisions. When updating, match the existing writing style.
- **Freshness is the #1 priority.** A doc that was accurate 6 months ago but wrong today is worse than no doc at all.
- **Prefer surgical fixes over rewrites.** Change the wrong path, update the outdated example, remove the completed TODO. Don't restructure the whole document.
- **Always explain what you changed and why.** The user should be able to review your updates and understand each one.
- **Ask before changing intent.** Factual corrections are fine to make directly. But if a doc says "we plan to migrate to PostgreSQL" and the project now uses MongoDB, ask the user — maybe they abandoned the plan, or maybe it's still in progress.
