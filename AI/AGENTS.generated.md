# Coding Style

## General

Adopt a "sentence readable" approach:

- Code should read like a sentence
- Prefer descriptive names over short names
- Long names are perfectly acceptable
- Use `isX` and `hasX` naming conventions for boolean checks
- Declare more variables to avoid nested or long expressions

## File Organization

MANY SMALL FILES > FEW LARGE FILES:

- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large components
- Organize by feature/domain, not by type

## Comments

- Write docstrings. Conventions: typescript/tsx (TSDoc), python (google docstrings), go (GoDoc)
- Write comments for complex code that is difficult to understand, not for obvious code
- Comments explain why, not what - provide enough context for someone to write tests against intended behaviour

## Code Quality Checklist

Before marking work complete:

- [ ] Code is readable and well-named
- [ ] Functions are small (<30 lines)
- [ ] Functions have docstrings
- [ ] Files are focused (<800 lines)
- [ ] Use early returns
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)

# Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.
- You MUST keep doc websites, public APIs, and other documentation up to date.
- You MUST reference the docs/codemaps/README.md when trying to explore code or find a specific piece of code. They will quickly tell you where things are located. As a result, it is also important to keep these up to date.

## Rules vs docs/

`.claude/rules/*.md` are path-gated imperative directives — kept under ~30 lines each, no prose. They tell agents what to do / not do. Background, references, decision, and explanations live in `docs/`. When trimming a rule, move the "why" to the relevant `docs/` file (or create a new one).

# Git Workflow

## Worktree

If you are starting in a new worktree, check what languages, runtimes, dependencies, etc. you need to install and get those up and running first. Some may already be available, but not all.

## Branch Workflow

You _cannot_ push directly to main, don't even try.

Always start your work in a new branch created from the currently checked out branch

Naming convention: `<type>/<description>`, where type is one of the conventional commit types:

- feat: new feature
- fix: bug fix
- refactor: refactoring
- docs: documentation
- test: adding missing tests
- chore: maintenance
- perf: performance improvement
- ci: CI related changes

## Committing

The first line of a commit message should be a description of your your changed. Then the extended commit message needs to explain _why_ you changed it along with any necessary context.

GPG sign your commits if possible.

### Conventional commits

Every commit message follows the conventional commit format:

```
<type>: <short description>
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `perf`, `ci`

Keep the subject line under 70 characters. Add a body only when the "why" isn't obvious from the subject.

### Small, logical commits

Commit in small, focused chunks — each commit should be one logical change that is easy to review and revert.

- Don't bundle unrelated changes in a single commit
- Don't commit half-finished work that breaks the build

### Never Commit

- Secrets, API keys, passwords, or tokens
- `.env` files (these belong in `.gitignore`)
- Large binary files without good reason

## Pull Request/Merge Workflow

Important: each PR should be small, focused, and self-contained. Do NOT bundle multiple issues into a single PR. If multiple issues come up, create a branch, start a subagent on the issue, or make a note of it.

When pushing, merging or creating PRs:

1. All changes are committed
2. The branch is up to date with main (rebase if needed)
3. Verification has passed (lint, type-check, tests, build)
4. Analyze full commit history of the branch (not just latest commit)
5. Use `git diff [base-branch]...HEAD` to see all changes
6. Use a fast-forward merge strategy if possible

Once you have merged your branch, make sure you delete the local branch

# Security Guidelines

## Mandatory Security Checks

Before ANY commit:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on endpoints
- [ ] Error messages don't leak sensitive data

## Secret Management

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx";

// ALWAYS: Private environment variables
const apiKey = process.env.OPENAI_API_KEY;

if (!apiKey) {
  throw new Error("OPENAI_API_KEY not configured");
}
```

## Security Response Protocol

If security issue found:

1. STOP immediately
2. Tell the user
3. Use **security-reviewer** agent
4. Fix CRITICAL issues before continuing
5. Review entire codebase for similar issues

# Subagents

Spawn subagents to isolate context, parallelize independent work, or offload bulk mechanical tasks. Don't spawn when the parent needs the reasoning, when synthesis requires holding things together, or when spawn overhead dominates.

Pick the cheapest model that can do the subtask well. For example, Claude Code models:

- Haiku: bulk mechanical work, no judgment
- Sonnet: scoped research, code exploration, in-scope synthesis
- Opus: subtasks needing real planning or tradeoffs

If a subagent realizes it needs a higher tier than itself, return to the parent.

Parent owns final output and cross-spawn synthesis. User instructions override.

# Testing Requirements

## Core Principle

Don't just write smoke tests.

Test intended behaviour, not implementation details. At every level, assert that the right thing _happened_ — not just that the right type came back or the right dependency was called.

- **Unit**: verify the returned value is correct for the input and that meaningful state changed.
- **Integration**: verify the combined flow produces the right data transformation or side effect, not just that services connect.
- **E2E**: verify user-visible outcomes (content, redirects, confirmations), not internal state.

## Test-Driven Development

If a testing framework has been set up, always use TDD. Do not set up a new testing framework unprompted.

Use **tdd-workflow** skill to help you.

1. Write test first (RED) — run it, confirm it fails
2. Write minimal implementation (GREEN) — run it, confirm it passes
3. Refactor (IMPROVE) — verify coverage (80%+)

## Coverage

Minimum: 80%.

- **Unit tests** — individual functions, utilities, components
- **Integration tests** — API endpoints, database operations (if applicable)
- **E2E tests** — critical user flows (if applicable)

## E2E Test Guidelines

E2E tests verify a user can complete a real workflow start-to-finish, interacting through the UI, CLI, or public API surface.

**Should verify:**

- A user can complete a flow end-to-end (e.g. sign up → create resource → see it listed)
- Visible outcomes: page content, redirects, emails, downloaded files
- Multiple systems working together in a real scenario
- Error states a user would encounter (404s, validation messages, permission denied)

**Should not verify:**

- Response shapes or data structures (integration/contract test)
- Arguments passed to internal functions (unit test with spies)
- Database state, internal method calls, or intermediate transformations
- API field values unless directly visible to the user

**Rule of thumb:** if the assertion requires knowledge of the code's internals rather than its observable behaviour, it doesn't belong in an E2E test.

## Troubleshooting Test Failures

1. Check test isolation
2. Verify mocks are correct
3. Fix implementation, not tests (unless the test is wrong)

If you encounter a failing test outside your current scope, inform the orchestrator to create a new worktree. Do not skip it.

# Tools

Use the right tool for the job - do not just resort to manual search and edits. Below are some examples of efficient tools for different tasks.

## CLI

[rtk](https://github.com/rtk-ai/rtk) is available for many Bash commands to help save tokens. It works by intercepting commands and compressing their output. In order to take advantage of this, you _must_ use the Bash tool to call these commands instead of builtin tools like Read, Grep, and Glob.

Shortlist of commands that can be intercepted:

`ls` List directory contents with token-optimized output (proxy to native ls)
`tree` Directory tree with token-optimized output (proxy to native tree)
`read` Read file with intelligent filtering
`git` Git commands with compact output
`gh` GitHub CLI (gh) commands with token-optimized output
`find` Find files with compact tree output (accepts native find flags like -name, -type)
`diff` Ultra-condensed diff (only changed lines)
`log` Filter and deduplicate log output
`grep` Compact grep - strips whitespace, truncates, groups by file
`wget` Download with compact output (strips progress bars)
`wc` Word/line/byte count with compact output (strips paths and padding)
`npm` npm run with filtered output (strip boilerplate)
`npx` npx with intelligent routing (tsc, eslint, prisma -> specialized filters)
`curl` Curl with auto-JSON detection and schema output

You can see the full list using `rtk --help`.

## Code Intelligence

For an LSP-centric workflow, you should declare/initialize before you use/reference a variable, otherwise you'll be flooded with stale errors.

Prefer LSP over Grep/Glob/Read for code navigation:

- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

Before renaming or changing a function signature, use `findReferences` to find all call sites first.

Use Grep/Glob only for text/pattern searches (comments, strings, config values) where LSP doesn't help.

After writing or editing code, check LSP diagnostics before moving on. Fix any type errors or missing imports immediately.

## Structural Search

Prefer structural matchers over regex when the pattern has syntactic shape (a call, a signature, an import, a JSX prop). They eliminate false positives from comments/strings and survive formatting changes.

- `ast-grep` (`sg`) — pattern-based search/rewrite by AST. Use for: finding all call sites of a function with a specific argument shape, codemods, refactors that regex would mangle. Example: `sg -p 'console.log($$$)' -l ts`
- `semgrep` — rules-based static analysis with taint tracking. Use for: security audits (injection, SSRF, secrets), enforcing project-specific anti-patterns, bulk lint rules across languages. Heavier than ast-grep but supports dataflow.
- `tree-sitter` — the underlying parser. Use directly via `tree-sitter parse` when you need a raw syntax tree to script against, or when ast-grep's pattern DSL can't express what you need.

Rule of thumb: regex for text, ast-grep for syntax, semgrep for semantics.

## Data Wrangling

For structured output (JSON/YAML/CSV/logs), pipe through a parser instead of grepping raw text.

- `jq` — JSON filter/transform. Default for any JSON.
- `yq` — same DSL as jq, for YAML/TOML/XML.
- `gron` — flatten JSON to grep-able paths (`gron file.json | grep foo`). Great when you don't yet know the shape.

## Codemaps

Projects will usually have a `docs/codemaps/` directory. It acts as an index of the codebase to help you find the specific files that you're looking for based on their domain

# Workflow

## Core Principles

These are the core principles you must follow for your work:

1. Don't assume. Don't hide confusion. Surface tradeoffs.
2. Minimum code that solves the problem. Nothing speculative.
3. Touch only what you must. Clean up only your own mess.
4. Define success criteria. Loop until verified.

Your work will be reviewed by both a senior engineer and a second AI coding agent (e.g. OpenAI Codex).

## Planning

Always create a plan first. Call frank - he's good at planning. Have the plan and spec reviewed before proceeding with implementation.

If a plan has been established, do NOT deviate from it. If you need to adjust for some reason, then pause and discuss first.

Do NOT reference plan files in code comments, rules files, or docs/ reference files.

Delete the plan file after the work is complete.

## When Uncertain

- Always ask before proceeding
- One decision at a time - don't present branching decisions that require multiple follow-ups. Instead, make a note and should circle back when needed.
- When presenting alternatives: pros, cons, and a recommendation given the context

## When Exploring and Reviewing

- Question my approach if you see issues
- Focus on: bugs, security, performance, architectural concerns
- Minor stylistic nitpicks can be noted as an aside
- Stop and ask before making significant changes

## When debugging

- Run unit tests to help keep you on track
- Use logging freely to identify root cause, but make sure to remove logging before committing
- When fixing frontend issues, make sure you proactively use the agent browser skill in headed mode

