# Documentation

- Create README.md files for subdirectories/submodules when nuance and detail is needed for that section.
- When working with subdirectories, make sure to first check if it has an associated README.md that provides more specific information.
- Keep repo/subdirectory README.md and project AGENTS.md/CLAUDE.md files up to date when making significant changes.
- You MUST keep doc websites, public APIs, and other documentation up to date.
- You MUST reference the docs/codemaps/README.md when trying to explore code or find a specific piece of code. They will quickly tell you where things are located. As a result, it is also important to keep these up to date.

# Rules vs docs/

`.claude/rules/*.md` are path-gated imperative directives — kept under ~30 lines each, no prose. They tell agents what to do / not do. Background, references, decision, and explanations live in `docs/`. When trimming a rule, move the "why" to the relevant `docs/` file (or create a new one).
