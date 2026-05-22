# Tools

Use the right tool for the job - do not just resort to manual search and edits. Below are some examples of efficient tools for different tasks.

## CLI

[rtk](https://github.com/rtk-ai/rtk) is available for many Bash commands to help save tokens. It works by intercepting commands and compressing their output. In order to take advantage of this, you _must_ use the Bash tool instead of builtin tools like Read, Grep, and Glob.

### Golden Rule

**Always prefix commands with `rtk`**. It is always safe to use - if there is no `rtk` variant, it will just fall back to the regular command.

**Important**: Even in command chains with `&&`, use `rtk`:

```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

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
