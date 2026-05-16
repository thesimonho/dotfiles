# Plugin and Skills

Default model: `sonnet` — when dispatched as a subagent, use `model: "sonnet"` unless the user specifies otherwise.

Default directory: `docs/plugin/`

Scaffold and maintain a Claude Code plugin, a Vercel npx skills package, or both. This documentation type handles the meta-problem: helping a project distribute its own AI-powered skills and agents.

The primary concern of this documentation type is to make sure an agent CLI has enough reference information to help a developer work with the project. The audience is _not_ the developer themselves. The difference is subtle, but important. The core question is "what information do I need to provide to an agent to make it an expert on my project?"

## Dual ecosystem

There are two distribution ecosystems. Both can coexist in the same repository.

### Claude Code plugins

- Distributed via marketplace repositories
- Installed with `/plugin install plugin-name@marketplace-repo`
- Skills are namespaced: `/plugin-name:skill-name`
- Agents are namespaced: `plugin-name:agent-name`
- The plugin name comes from `plugin.json` `name` field
- The skill name comes from the **directory name** under `skills/`
- Supports skills, agents, hooks, and MCP server configurations

### Vercel npx skills

- Distributed via the GitHub repository itself
- Installed with `npx skills add owner/repo`
- Skills are flat (no namespace): `/skill-name`
- The skill name comes from the **frontmatter `name` field** in `SKILL.md`
- Falls back to directory name if no frontmatter name is set
- Supports skills only (no agents, hooks, or MCP)

### Why this matters

The same `SKILL.md` file serves both ecosystems, but the invocation command is different because one uses the directory name (namespaced) and the other uses the frontmatter name (flat).

Example: a plugin called `dodo` with a skill in directory `do/` and frontmatter `name: dodo`:

- Claude Code users type: `/dodo:do`
- npx skills users type: `/dodo`

Name skills carefully. Always tell the user both resulting invocation commands when helping them choose names.

## Directory structure

The canonical layout for a project that supports both ecosystems:

```
project-root/
├── .claude-plugin/
│   └── plugin.json              # Required for Claude Code plugins
├── skills/
│   └── <skill-directory-name>/
│       ├── SKILL.md             # Required — frontmatter + instructions
│       └── (supporting files)   # Optional — referenced by SKILL.md
├── agents/
│   └── <agent-name>.md          # Optional — Claude Code only
├── hooks/
│   └── hooks.json               # Optional — Claude Code only
└── .mcp.json                    # Optional — MCP server configs
```

### plugin.json

Required for Claude Code plugin distribution. Lives at `.claude-plugin/plugin.json`.

| Field         | Required | Description                                                                                      |
| ------------- | -------- | ------------------------------------------------------------------------------------------------ |
| `name`        | Yes      | Plugin name. Becomes the namespace prefix for all skills and agents. Lowercase, hyphens allowed. |
| `version`     | Yes      | Semver version string (e.g., `"1.2.0"`)                                                          |
| `description` | Yes      | Short description shown in the plugin manager                                                    |

### SKILL.md frontmatter

Every skill needs a `SKILL.md` file with YAML frontmatter.

Web search for the latest SKILL.md frontmatter documentation before creating skills. New fields are added regularly.

### Agent definitions

Agents are Claude Code only — they are not supported by npx skills.

Agents live in the `agents/` directory as individual markdown files with YAML frontmatter.

| Field         | Required | Description                                                             |
| ------------- | -------- | ----------------------------------------------------------------------- |
| `name`        | Yes      | Agent identifier. Namespaced as `plugin-name:agent-name`.               |
| `description` | Yes      | What the agent does. Claude uses this to decide when to delegate.       |
| `model`       | No       | Model override (e.g., `haiku` for cheap tasks, `opus` for complex ones) |
| `tools`       | No       | Array of tools the agent can use                                        |
| `memory`      | No       | Memory scope: `project`, `user`, or `global`                            |
| `color`       | No       | Terminal color for the agent's output                                   |

The filename (without `.md`) becomes the agent name within the plugin namespace.

## Naming conventions

When helping the user name their skills:

1. **Choose the plugin name** (goes in `plugin.json` `name`). This becomes the Claude Code namespace prefix for everything.
2. **For each skill, choose two names:**
   - **Directory name**: becomes `{plugin-name}:{directory-name}` in Claude Code
   - **Frontmatter `name`**: becomes `/{frontmatter-name}` in npx skills
3. **Always show the user both resulting commands** before they commit to a name. Example:
   > Directory: `generate`, frontmatter name: `scaffold`
   >
   > - Claude Code: `/my-plugin:generate`
   > - npx skills: `/scaffold`

## What to generate as skills

Skills are not documentation. A site page explains _to a human_ how something works. A skill instructs _an agent_ on how to help a developer work with something. The content, structure, and level of detail are fundamentally different.

### The core question

For each skill you create, ask: **"What does a developer repeatedly ask an agent to do with this project, and what context does the agent need to do it well?"**

A good skill saves the developer from having to explain the same project-specific context every time. Without the skill, the developer types "set up a new API endpoint" and then spends 5 messages correcting the agent's assumptions about the project's routing conventions, middleware stack, error handling patterns, and test structure. With the skill, the agent already knows all of that.

### Skill content is procedural, not explanatory

Documentation explains concepts. Skills give orders. Compare:

**Site page** (for humans):

> Our API uses a middleware chain for authentication. Requests first pass through `authMiddleware` which validates the JWT token, then `rateLimitMiddleware` which enforces per-user rate limits...

**Skill** (for agents):

> When creating a new API endpoint:
>
> 1. Create the route handler in `src/api/routes/`. Follow the pattern in `src/api/routes/users.ts`.
> 2. Register the route in `src/api/index.ts` — add it to the router array.
> 3. Add the `authMiddleware` and `rateLimitMiddleware` to the route chain. Every authenticated endpoint uses both.
> 4. Create a corresponding test file in `tests/api/`. Use `tests/api/users.test.ts` as a template.
> 5. Add the endpoint to the OpenAPI spec in `docs/openapi.yml`.

The skill doesn't explain _why_ the middleware exists. It tells the agent _what to do_ and _where to do it_, referencing real files as patterns to follow.

### What makes a good skill

- **Encodes project conventions** that aren't obvious from reading a single file. Where do things go? What patterns do other files follow? What's the checklist an experienced contributor would have internalized?
- **References real files as templates.** Instead of describing a pattern abstractly, point to a concrete example: "follow the pattern in `src/api/routes/users.ts`". The agent can read that file and replicate the structure.
- **Includes guardrails.** What should the agent _not_ do? Common mistakes, deprecated patterns, files it shouldn't touch, conventions it must follow.
- **Stays actionable.** Every sentence should either tell the agent what to do, where to look, or what to avoid. Remove anything that's purely informational — that belongs in references or the site.

### Common skill types to suggest

Analyze the project and suggest skills for recurring developer workflows. Some examples:

| Project signal                 | Suggested skill | What it does                                                                                |
| ------------------------------ | --------------- | ------------------------------------------------------------------------------------------- |
| Has API routes                 | `new-endpoint`  | Scaffolds a new API endpoint following project conventions                                  |
| Has a component library        | `new-component` | Creates a new component with tests, stories, and exports                                    |
| Has database models            | `new-model`     | Creates a model, migration, and repository following existing patterns                      |
| Has a CLI                      | `new-command`   | Adds a new CLI command with argument parsing and help text                                  |
| Has a test suite               | `test-guide`    | Explains the project's testing conventions so the agent writes tests correctly              |
| Has complex config             | `setup`         | Walks through local development setup, env vars, and dependencies                           |
| Has deployment pipeline        | `deploy-guide`  | Provides the agent context about the deployment process and environment                     |
| Has multiple packages/services | `architecture`  | Gives the agent a map of the system so it understands boundaries and communication patterns |

Don't suggest all of these — only the ones that match what the project actually has. Propose 3-5 skills maximum to start.

## Create flow

1. **Ask which ecosystems to support.** Claude Code plugin, npx skills, or both. This determines what files to scaffold.

2. **Name everything.** Walk through the naming decision guide above for the plugin and each skill. Show resulting invocation commands for each ecosystem the user selected.

3. **Scaffold the directory structure.** Create the directories and files per the canonical layout above. Only create what's needed for the chosen ecosystem(s):
   - Both: everything in the layout
   - Claude Code only: `.claude-plugin/`, `skills/`, `agents/` (if needed), `hooks/` (if needed)
   - npx skills only: `skills/` directory with `SKILL.md` files

4. **Create `plugin.json`.** Fill in the user's metadata.

5. **Create SKILL.md files.** Write proper frontmatter for each skill. Web search for the latest frontmatter documentation to ensure all available fields are included. Write the skill body as a clear, structured prompt that an AI agent can follow.

6. **Marketplace reminder.** If the user chose Claude Code plugin distribution, remind them:
   - They need a marketplace repository for end users to discover and install the plugin
   - The marketplace repo is separate from the plugin source repo
   - Point them to the Claude Code plugin marketplace documentation

7. **npx skills reminder.** If the user chose npx skills distribution, remind them:
   - The repo itself is the distribution mechanism — users install with `npx skills add {owner}/{repo}`
   - The repo must be public on GitHub for users to install it

8. **Generate a README** for the plugin directory explaining the structure and how to test locally:
   - Claude Code: `claude --plugin-dir ./` to load the plugin from a local directory
   - npx skills: install skills directly from the local path

## Update flow

Important: if you're searching or reading documents, it's much faster to do it in parallel.

1. **Read all skill and agent files.** Catalog every `SKILL.md` and agent markdown file.

2. **Check frontmatter currency.** Web search for the latest frontmatter specification. Are there new fields available that should be added? Are existing fields using deprecated syntax?

3. **Check description accuracy.** Do skill and agent descriptions accurately reflect what they currently do? Descriptions drift as functionality evolves.

4. **Check `plugin.json`.** Is the version current? Does the description still match the plugin's capabilities? Are keywords up to date?

5. **Suggest new skills.** If the project has added features that would make good skills, suggest them to the user. Explain what each proposed skill would do and how it would be invoked.

6. **Verify structure.** Does the directory layout follow conventions? Are there orphaned files not referenced by any skill? Do all supporting files referenced in SKILL.md bodies actually exist?

7. **Verify consistency.** Do naming conventions match across all skills? Are frontmatter styles consistent? Do all skills follow the same structural patterns?

## Principles

- **Frontmatter is the skill's resume.** The `description` field determines whether Claude ever invokes the skill. Write it like an elevator pitch — the first 250 characters matter most.
- **Skills are prompts.** The body of a SKILL.md is a system prompt for an AI agent. Write it as clear, structured instructions with concrete steps — not vague guidance.
