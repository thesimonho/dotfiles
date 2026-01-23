---
name: scaffold
description: Set up new projects with frameworks or languages in the current working directory. Use when the user explicitly requests to scaffold, set up, initialize, or create a new project. Supports any language setup or framework. Proactively searches for latest versions and best practices, surfaces choices to the user when multiple options exist.
disable-model-invocation: false
user-invocable: true
---

# Scaffold

Automate the setup of new framework or language projects with current best practices, dependency installation, and git initialization.

## Core Workflow

Follow this sequence for every scaffolding request:

### 1. Detect Existing Context

Check the current working directory for existing configuration files that inform setup decisions:

- **Version managers**: `.mise.toml`, `.tool-versions`, `.nvmrc`, `.python-version`, `rust-toolchain.toml`, etc.
- **Existing configs**: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.
- **Git**: Check if `git status` works (already initialized)

Use this context to inform tool choices and avoid conflicts.

### 2. Search for Latest Best Practices

**CRITICAL**: Always search the web for current official information. Tools and frameworks evolve rapidly, and documentation becomes outdated quickly. Use the official documentation as a reference.

Search queries should include the current year. Examples:

```
"Next.js setup 2026 official"
"Python project structure 2026"
"FastAPI project setup best practices"
```

Focus on:

- Latest stable version numbers
- Current recommended tooling
- Modern best practices
- Breaking changes from previous versions

### 3. Identify Decision Points

Determine what choices need user input. Common decision points:

**Frameworks (typically have CLI tools with options):**

- Next.js: App Router vs Pages Router
- React: Vite vs Create React App vs Next.js
- Python web: FastAPI vs Django vs Flask
- React Native: Expo vs bare workflow

**Language projects (more tooling choices):**

- Python: uv vs Poetry vs pip-tools vs hatch
- Node.js: npm vs pnpm vs yarn vs bun
- Go: standard module vs specific project layout (cmd/pkg, monorepo, etc.)
- Rust: binary vs library, workspace setup

**Additional choices:**

- TypeScript vs JavaScript
- Testing framework preferences
- Linting/formatting tools
- CI/CD setup

### 4. Surface Choices to User

When multiple valid approaches exist, ask the user for their preference. Use AskUserQuestion tool with:

- Clear descriptions of each option
- Recommendations based on latest best practices when appropriate
- Context from the web search

Example:

```
"I found that Next.js 15.2 (latest) uses the App Router by default. Which would you prefer?"
- App Router (Recommended for new projects) - Modern routing with Server Components
- Pages Router - Traditional routing, more examples available
```

### 5. Execute Scaffolding

Run the appropriate commands based on user choices:

**Framework CLI tools:**

```bash
# Next.js
npx create-next-app@latest

# Vite
npm create vite@latest

# FastAPI (no official CLI, create structure)
mkdir -p app tests
```

**Language initialization:**

```bash
# Python with uv
uv init

# Go
go mod init

# Rust
cargo init
```

Follow the framework's recommended setup flow. Pay attention to prompts from CLI tools.

### 6. Create README.md

Generate a project-specific README with:

- Project name and brief description
- Setup instructions (how to install dependencies)
- How to run development server
- How to run tests (if testing is set up)
- Tech stack summary

Keep it concise and immediately useful.

### 7. Create .gitignore

Create an appropriate .gitignore for the language/framework

- Choose the correct template from <https://github.com/github/gitignore>

Alternatively:

- Use framework CLI's generated .gitignore if provided
- Otherwise, generate one covering:
  - Language-specific patterns (node_modules/, **pycache**/, target/, etc.)
  - IDE files (.vscode/, .idea/, \*.swp)
  - Environment files (.env, .env.local)
  - Build outputs (dist/, build/, \*.pyc)
  - OS files (.DS_Store, Thumbs.db)

### 8. Initialize Git

```bash
git init
```

Skip if git is already initialized (detected in step 1).

### 9. Install Dependencies

Run the appropriate dependency installation command:

```bash
# Node.js
npm install  # or pnpm install, yarn, bun install

# Python
uv sync  # or poetry install, pip install -e .

# Go
go mod tidy

# Rust
cargo build
```

Monitor output for errors. If installation fails, troubleshoot before proceeding.

### 10. Verify Setup

Run a quick verification that the setup works:

**Web frameworks:**

```bash
# Start dev server briefly, then stop it
npm run dev  # or equivalent
# Check that it starts without errors, then Ctrl+C
```

**CLI tools/libraries:**

```bash
# Run tests if any
npm test  # or pytest, go test, cargo test

# Or verify build
npm run build  # or cargo build
```

Confirm no errors before proceeding.

### 11. Make Initial Commit

```bash
git add .
git commit -m "Initial commit: scaffold <framework/language> project

Set up <framework/language> project with <key tools/features>.
```

### 12. Provide Next Steps

Give the user clear, actionable next steps:

```
✅ Project scaffolded successfully!

Next steps:
1. Start development: npm run dev
2. Open http://localhost:3000 in your browser
3. Edit app/page.tsx to start building
4. Run tests: npm test

Tech stack:
- Next.js 15.2 (App Router)
- TypeScript
- Tailwind CSS
- ESLint
```

## Framework-Specific Patterns

### Next.js

- Use `create-next-app` with latest version
- Ask about App Router vs Pages Router
- Ask about TypeScript (usually yes)
- Ask about Tailwind CSS
- Ask about ESLint

### React (non-Next.js)

- Recommend Vite over Create React App
- Ask about TypeScript
- Consider if they need a framework (suggest Next.js for full apps)

### Python Web (FastAPI/Django/Flask)

- No official scaffolding CLI for FastAPI - create structure manually
- Django has `django-admin startproject`
- Ask about project structure preferences
- Ask about package manager (uv is fastest and modern)

### Python (general project)

- Detect existing version managers (.mise.toml, etc.)
- Ask about package manager: uv (recommended), Poetry, pip-tools, hatch
- Create minimal structure: src/ layout or flat layout
- Set up pyproject.toml

### Go

- Use `go mod init <module-path>`
- Ask if they want standard layout (cmd/, pkg/, internal/)
- No dependency installation needed (go mod tidy handles it)

### Rust

- Use `cargo init` (binary) or `cargo init --lib` (library)
- Ask binary vs library
- Ask about workspace setup if multiple crates

## Important Considerations

**Stay Current**: Search for latest versions and practices every time. Don't rely on cached knowledge.

**Respect Existing Setup**: If the directory already has configuration files, integrate with them rather than overwriting.

**Minimal by Default**: Don't over-engineer. Set up what's requested, not every possible feature.

**User Preferences**: Always surface meaningful choices rather than making assumptions.

**Verification**: Always verify the setup works before committing. Catch errors early.

**Clear Communication**: Keep the user informed at each step. Show what's being installed, what choices were made, and what the next steps are.
