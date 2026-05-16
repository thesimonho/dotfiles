# Codemaps

Default model: `haiku` — when dispatched as a subagent, use `model: "haiku"` unless the user specifies otherwise.

Default directory: `docs/codemaps/`

Codemaps are structured maps of the codebase designed for AI agents. They let an agent understand project architecture, find the right files, and navigate between modules — without reading every file in the repository.

## Structure

### Barrel index

`docs/codemaps/README.md` is the entry point. It acts as a table of contents for all codemaps in the project.

Format:

```markdown
# Codemaps — {Project Name}

{2-3 sentence architecture overview: what the project does, the main technology stack, and the high-level module boundaries.}

## Architectural patterns

- {Pattern 1: e.g., "Event-driven message bus connecting all services"}
- {Pattern 2: e.g., "Repository pattern for all database access"}

## Directory Map

| Directory   | Description                                  | Codemap               |
| ----------- | -------------------------------------------- | --------------------- |
| `src/auth/` | OAuth2 authentication and session management | [auth](./src/auth.md) |
| `src/api/`  | REST API route handlers and middleware       | [api](./src/api.md)   |
| ...         | ...                                          | ...                   |

## How to use these codemaps

Start here. Find the module relevant to your task in the table above, then read its codemap for file-level detail. Each codemap lists every file, its purpose, key exports, and how it connects to other modules.
```

### Subdirectories

Mirror the project's own directory structure. If the project has `src/auth/`, the codemap lives at `docs/codemaps/src/auth.md`. This makes it trivial for agents to find the codemap for any source directory.

### Granularity rule

Create one codemap per directory that has **3 or more files with meaningful logic**. Skip directories that only contain:

- Config files (e.g., a lone `tsconfig.json`)
- Generated output (e.g., `dist/`, `build/`)
- Vendored dependencies (e.g., `vendor/`, `node_modules/`)
- Test files — unless the project has a dedicated testing module worth mapping

### Size limit

Keep individual codemap files under 200 lines. If a module is larger, split into sub-codemaps and link between them. This saves you from having to read through a large file to find the right one.

## Content specification

Each codemap file should contain the following sections. Use this as a template:

```markdown
# {Module Name}

{1-2 sentence summary of what this module does and why it exists.}

## Files

| File           | Description                                                             |
| -------------- | ----------------------------------------------------------------------- |
| `handler.ts`   | Processes incoming webhook events and dispatches to the correct service |
| `validator.ts` | Schema validation for webhook payloads using Zod                        |
| ...            | ...                                                                     |

## Key exports

| Symbol              | File           | Description                                                                 |
| ------------------- | -------------- | --------------------------------------------------------------------------- |
| `WebhookHandler`    | `handler.ts`   | Main class — instantiated once at app startup, processes all webhook events |
| `validatePayload()` | `validator.ts` | Called by the handler before processing. Returns a typed payload or throws. |
| ...                 | ...            | ...                                                                         |

## Relationships

- **Imports from**: `src/auth/` (session tokens), `src/database/` (event storage)
- **Used by**: `src/api/webhooks.ts` (route handler), `src/workers/retry.ts` (dead letter queue)

## Entry point

Start with `handler.ts` — it's the central dispatch for this module. Everything else is called from there.

## Patterns

{Only include this section if the module uses a non-obvious pattern.}

- Uses the chain-of-responsibility pattern for webhook processing. Each handler in `processors/` implements `WebhookProcessor` and is registered in `handler.ts`.
```

### Description quality

Descriptions must be specific enough that an agent can find the right file without reading it.

- Bad: "Handles authentication"
- Good: "OAuth2 token refresh logic and session management for the REST API"
- Bad: "Utility functions"
- Good: "String sanitization, URL normalization, and retry-with-backoff helper used across all API clients"

## External tool detection

Before generating or updating codemaps, check whether the user has external tools available that can extract structured information from source code. These tools are faster, more accurate, and use less context than reading full files.

Run detection once per session and cache the results. Check each category independently — a project may benefit from tools in multiple categories.

### AST parsers

Extract exports, imports, symbols, and signatures directly from source code.

| Tool                | Check                     | Best for                        | Example usage                                                                                                                                                                                                       |
| ------------------- | ------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ast-grep            | `ast-grep --version`      | Multi-language pattern matching | `ast-grep --pattern 'export function $NAME($$$PARAMS): $RET' --json src/`                                                                                                                                           |
| tree-sitter CLI     | `tree-sitter --version`   | Multi-language full parse trees | `tree-sitter parse src/auth/handler.ts`                                                                                                                                                                             |
| TypeScript compiler | `tsc --version`           | TS/JS export extraction         | `tsc --declaration --emitDeclarationOnly --outDir /tmp/dts src/index.ts`                                                                                                                                            |
| Go toolchain        | `go version`              | Go package inspection           | `go doc ./src/auth/...`                                                                                                                                                                                             |
| Python ast          | `python3 -c "import ast"` | Python symbol extraction        | `python3 -c "import ast, json, sys; print(json.dumps([node.name for node in ast.parse(open(sys.argv[1]).read()).body if isinstance(node, (ast.FunctionDef, ast.ClassDef, ast.AsyncFunctionDef))]))" src/handler.py` |
| Rust analyzer       | `rust-analyzer --version` | Rust symbol and type info       | `cargo doc --document-private-items --no-deps`                                                                                                                                                                      |

### Dependency graph tools

Map inter-module relationships for the **Relationships** section.

| Tool           | Check                      | Best for                            | Example usage                            |
| -------------- | -------------------------- | ----------------------------------- | ---------------------------------------- |
| madge          | `npx madge --version`      | JS/TS import graphs                 | `npx madge --json src/`                  |
| dpdm           | `npx dpdm --version`       | JS/TS circular dependency detection | `npx dpdm --tree --json src/index.ts`    |
| depgraph (Go)  | `go version`               | Go package dependencies             | `go list -json ./...`                    |
| pipdeptree     | `pipdeptree --version`     | Python package dependencies         | `pipdeptree --json`                      |
| cargo-depgraph | `cargo depgraph --version` | Rust crate dependencies             | `cargo depgraph --dedup-transitive-deps` |

### Code analysis tools

Extract higher-level structural information like complexity, entry points, and dead code.

| Tool                    | Check                                                                            | Best for                                | Example usage                                                   |
| ----------------------- | -------------------------------------------------------------------------------- | --------------------------------------- | --------------------------------------------------------------- |
| ctags / universal-ctags | `ctags --version`                                                                | Multi-language symbol indexing          | `ctags -R --output-format=json --fields=+n src/`                |
| LSP                     | Check if `documentSymbol` or `goToDefinition` tools are available in the session | Definitions, references, call hierarchy | Use `goToDefinition`, `findReferences`, `documentSymbol`        |
| jq                      | `jq --version`                                                                   | Parsing JSON output from other tools    | `ast-grep --pattern 'export $$$' --json src/ \| jq '.[] .text'` |

LSP availability depends on the environment. In Claude Code, LSP tools (`documentSymbol`, `findReferences`, `goToDefinition`, `hover`, `incomingCalls`, `outgoingCalls`) are available automatically when a language server is running for the project. In other environments, check whether these tools exist in your tool list before attempting to use them. If LSP is unavailable, prefer ctags or ast-grep as alternatives for symbol and reference lookups.

### What to extract

Use whichever tools are available to pull structured data for codemap sections:

| Codemap section | What to extract                                                 | Best tools                        |
| --------------- | --------------------------------------------------------------- | --------------------------------- |
| Files table     | List of files with their top-level symbols to infer purpose     | ctags, ast-grep, tree-sitter      |
| Key exports     | Exported functions, classes, types, constants — with signatures | tsc, ast-grep, go doc, Python ast |
| Relationships   | Import statements → map which modules depend on which           | madge, go list, ast-grep          |
| Entry point     | File with the most inward references or the main/index file     | madge, LSP findReferences         |

### Fallback

If no external tools are available, fall back to reading source files directly and using LSP where available. The codemap output should be identical regardless of method — external tools are accelerators, not requirements.

## Create flow

1. Scan the full project directory structure. Build a mental model of the project layout.
2. Detect available AST parsers (see above).
3. Identify which directories warrant codemaps using the granularity rule above.
4. Propose the codemap structure to the user as a directory tree showing which codemaps will be created.
5. Ask for confirmation. The user may want to include or exclude specific directories.
6. Generate the barrel index first — this forces you to articulate the project's architecture up front.
7. Generate individual codemaps. If a parser is available, use it to extract exports and imports before writing each codemap. Use subagents to parallelize where possible, but ensure each subagent has the barrel index as context so descriptions are consistent.

## Update flow

Important: if you're searching or reading documents, it's much faster to do it in parallel.

1. Read the existing barrel index to understand current coverage.
2. Detect available AST parsers (see above).
3. Compare against the current project structure:
   - **New directories**: directories with 3+ logic files that don't have a codemap yet
   - **Removed directories**: codemaps for directories that no longer exist
   - **Changed directories**: directories where files have been added, removed, renamed, or significantly modified since the codemap was written
4. For changed directories: if a parser is available, extract current exports and imports, then diff against the existing codemap to find what actually changed. This avoids rewriting sections that are still accurate. Without a parser, re-read the source files. Pay attention to new exports, changed relationships, and renamed files.
5. For new directories: create new codemap files following the content specification.
6. For removed directories: delete the codemap file and remove its entry from the barrel index.
7. Update the barrel index to reflect all changes.
8. Preserve any hand-written notes or custom sections the user has added. Look for comments, non-standard sections, or content that doesn't match the template — this is intentional and should be kept.

## Principles

- Codemaps are for agents, not humans. Optimize for machine readability — be precise, structured, and exhaustive rather than narrative.
- Use relative paths from the project root everywhere.
- When in doubt about whether to include something, include it. An agent that finds too much information can filter; an agent that finds nothing is stuck.
- Codemaps should be regenerable. Don't store opinions, decisions, or plans in codemaps — that's what references are for.
