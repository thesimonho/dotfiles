# Tools

Use the right tool for the job - do not just resort to manual search and edits. Below are some examples of efficient tools for different tasks.

## Tool orchestration

Minimize model round trips. Before using tools, identify everything needed for the next meaningful decision.

- Batch independent calls whose results inform the same decision.
- Use workflows or programmatic tool calling for predictable multi-step collection, filtering, validation, polling, or mechanical work.
- Process and summarize intermediate results inside the workflow rather than returning raw output to the model.
- Do not batch dependent or risky mutations that require checking each result.
- Avoid retrieving unchanged state or rerunning passing checks without relevant changes.

Prefer one model decision around a batch or workflow over using the model as glue between mechanical steps.

## Code Intelligence

Prefer LSP over Grep/Glob/Read for code navigation:

- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

## Structural Search

Prefer structural matchers over regex when the pattern has syntactic shape (a call, a signature, an import, a JSX prop). They eliminate false positives from comments/strings and survive formatting changes. Examples: `ast-grep`, `tree-sitter`, and `semgrep`.

## Data Wrangling

For structured output (JSON/YAML/CSV/logs), pipe through a parser instead of grepping raw text. Examples: `jq`, `yq`, `gron`.
