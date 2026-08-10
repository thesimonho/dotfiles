# READMEs

Default location: alongside the code, one `README.md` per meaningful source directory.

A directory's `README.md` is the context an agent needs to work inside that directory. It explains what the directory is for, important notes, and how the directory connects to the rest of the project.

The README lives **in** the directory it describes. `src/auth/README.md` describes `src/auth/`. There is no separate index directory and no mirrored tree to keep in sync: an agent that opens a directory has already found its documentation, and a directory that moves or is deleted takes its README with it.

## Structure

### Root README

The project's root `README.md` is the entry point. It keeps its normal job — what the project is, how to install and run it — and adds a short map of the top-level directories so an agent knows where to go next.

Add a section like this:

```markdown
## Project layout

| Directory   | What lives there                             |
| ----------- | -------------------------------------------- |
| `src/auth/` | OAuth2 authentication and session management |
| `src/api/`  | REST API route handlers and middleware       |
| ...         | ...                                          |

Directories can have their own `README.md` with local-level details.
```

Do not link every nested README from the root. The point of the convention is that an agent finds the README by being in the directory, not by walking an index.

### Granularity rule

Write a `README.md` for a directory that has **3 or more files with meaningful logic**, or fewer files whose purpose or constraints are not obvious from their names. Skip directories that only contain:

- Config files (e.g., a lone `tsconfig.json`)
- Generated output (e.g., `dist/`, `build/`)
- Vendored dependencies (e.g., `vendor/`, `node_modules/`)
- Test files — unless the project has a dedicated testing module worth documenting

A nested directory gets its own README rather than a section in its parent's. Keep each README scoped to its own directory: if a README has to explain a sibling directory, the boundary is wrong, not the README.

## Content specification

The content of a README is directory-dependent. Generally:

1. High level summary of what the directory is for
2. Important notes about implementation that may be hidden or non-obvious
3. Prior decisions that should not be reversed without an explanation
4. How/where this directory is used within the larger project

The README is not a dumping ground or a file index. Write only key developer information.

### Path conventions

If you need to refer to files, write file names bare (`handler.ts`) when they sit in the documented directory, and repository-root-relative (`src/auth/session.ts`) when they don't. A README that has moved should still read correctly for its own files.

## Create flow

1. Scan the full project directory structure. Build a mental model of the project layout.
2. Identify which directories warrant a README using the granularity rule above.
3. Propose the set to the user as a directory tree showing which READMEs will be created, and flag any directory that already has a README so the user knows it will be extended rather than replaced.
4. Ask for confirmation. The user may want to include or exclude specific directories.
5. Write the root README's project-layout section first — this forces you to articulate the project's architecture up front.
6. Create the directory READMEs. Use subagents to parallelize where possible, but give each subagent the root README as context so descriptions are consistent.

## Update flow

Important: if you're searching or reading documents, it's much faster to do it in parallel.

1. Glob for existing `README.md` files to establish current coverage. Exclude generated, vendored, and build output directories.
2. Compare against the current project structure:
   - **New directories**: directories with 3+ logic files that have no README yet
   - **Removed directories**: nothing to do — a deleted directory took its README with it. Check the root README's layout table for a now-dangling row.
   - **Changed directories**: directories where files have been added, removed, renamed, or significantly modified since the README was written
3. For new directories: create the README following the content specification.
4. Update the root README's project-layout table if the top-level directories changed.

## Principles

- When in doubt about whether to include something, include it. An agent that finds too much information can filter; an agent that finds nothing is stuck.
- Never delete a README you did not generate without asking. Many projects already have hand-written directory READMEs.
