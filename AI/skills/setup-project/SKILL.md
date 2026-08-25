---
name: setup-project
description: Bootstrap a new local project and its GitHub delivery workspace. Use only when the user manually invokes this skill at the start of a project to set up initial project structure.
model: opus
disable-model-invocation: true
user-invocable: true
---

# Setup Project

Bootstrap the current directory as one project. Preserve existing work and stop before any step that would overwrite a file, remote, or GitHub resource.

Keep each step idempotent. Do not overwrite existing files, remotes, or configurations.

## Workflow

Track these steps explicitly and complete them in order.

### 1. Confirm the project boundary

- Resolve the current directory and confirm it is the directory the user intends to initialize.
- Inspect existing files, Git state, remotes, and applicable parent instructions.
- Do not initialize a home directory, workspace root, or other broad directory accidentally.

### 2. Initialize Git

- Run `git init` only when the directory is not already a Git repository.
- If Git already exists, preserve its current branch, history, configuration, and worktree state.

### 3. Establish agent instructions

- Create `AGENTS.md` if it does not exist. Start it with `# AGENTS` and a short note that project-specific agent instructions belong there.
- Preserve an existing `AGENTS.md` exactly.
- Create `CLAUDE.md` if it does not exist with exactly this content:

```markdown
@AGENTS.md
```

- If `CLAUDE.md` already exists, do not replace it. Explain any mismatch instead.

### 4. Create or link the GitHub repository

- Check whether an `origin` remote already exists.
- If `origin` exists, inspect it and reuse it. Do not create another repository or change the remote.
- If `origin` does not exist, confirm `gh` is authenticated, infer a sensible repository name from the directory, and ask the user for any unresolved owner, name, description, or visibility choice.
- Use `gh repo create` with the current directory as its source and configure the new repository as `origin`.
- Create and link the repository without pushing unless the user explicitly asks to publish commits.
- New repositories should always be created as Private.

### 5. Set up delivery tracking

- Make sure Projects are enabled in the GitHub repository.
- Invoke the `$kanban` skill with an explicit request to set up the GitHub Project board for the linked repository.
- Let the Kanban workflow inspect existing Projects, labels, Milestones, and Issues so it can reuse rather than duplicate them.
- Surface any GitHub authorization or ownership limitation to the user instead of silently skipping setup.

### 6. Scaffold the project

- Ask the user what they want to create, including the product or library purpose and any known language, framework, or runtime preferences.
- Invoke `$scaffold` with their answer and the current project context.
- Let the Scaffold workflow own current-version research, framework decisions, generated files, dependency installation, and scaffold verification.
- Ensure scaffolding preserves `AGENTS.md`, `CLAUDE.md`, the `origin` remote, and the GitHub Project created earlier.
- After scaffolding, replace the generic note in a newly created `AGENTS.md` with concise project-specific commands and conventions learned during scaffolding. Do not alter an `AGENTS.md` that predated this workflow unless the user approves.

### 7. Create the project baseline

Create the project baseline after scaffolding so every file reflects the selected language, framework, and runtime:

- Create `mise.toml` if it does not exist. Declare only the runtimes and tools the scaffolded project actually requires, using the versions selected or installed by the Scaffold workflow. Do not guess versions or replace an existing Mise configuration.
- Ensure a root `.gitignore` exists and covers the standard generated files, dependencies, build output, local environment files, editor files, and operating-system files for the scaffolded project type. Extend an incomplete generated `.gitignore` without removing existing entries; preserve intentional tracked files.
- Create a truly empty root `justfile` if it does not exist. Preserve an existing `justfile` exactly and do not add speculative recipes.
- Ensure a root `README.md` exists with the project name, a brief purpose, setup instructions, the primary development or usage command, verification commands, and a concise technology summary. Improve a scaffold-generated README only when those basics are missing; preserve useful generated guidance.
- Keep all baseline files consistent with the actual scaffold. Do not document commands, tools, or runtimes that were not installed and verified.

### 8. Worktree preparation

Git worktrees will probably be used at some point and you want to make sure they can scaffold themselves whenever they are created:

- Create a `.worktreeinclude` file in the root directory of the project. Write a list of untracked files that should be automatically copied to each new worktree (e.g. `.env`). Structure it like a `.gitignore`.

Add any setup and cleanup scripts that worktrees should run automatically. This is useful for things like creating an initial database, tearing down containers etc.

- Create `.codex/environments/environment.toml` with the following content:

```toml
# THIS IS AUTOGENERATED. DO NOT EDIT MANUALLY
version = 1
name = "<repo name>"

[setup]
script = "<setup command>"

[cleanup]
script = "<cleanup command>"
```

### 9. Create the glossary

- Create the `docs/` directory when needed.
- Create an empty `docs/glossary.md` if it does not exist.
- Preserve an existing glossary exactly; do not empty or replace it.
- Keep the new glossary truly blank until project domain terms are resolved.

### 10. Report the result

Summarize:

- the local Git repository and current branch;
- the instruction files created or preserved;
- the `origin` URL and repository visibility;
- the GitHub Project created or reused;
- what was scaffolded and how it was verified;
- the runtime pins and repository baseline files created or preserved;
- whether `docs/glossary.md` was created or preserved;
- any incomplete step and the exact action needed to unblock it.
