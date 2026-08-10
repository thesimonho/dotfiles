# Tools

Before manually reading source code files, check whether the user has external tools available that can extract structured information. These tools are faster, more accurate, and use less context than reading full files.

Run detection once per session and cache the results. Check each category independently — a project may benefit from tools in multiple categories.

## AST parsers

Extract exports, imports, symbols, and signatures directly from source code.

| Tool                | Check                     | Best for                        | Example usage                                                                                                                                                                                                       |
| ------------------- | ------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ast-grep            | `ast-grep --version`      | Multi-language pattern matching | `ast-grep --pattern 'export function $NAME($$$PARAMS): $RET' --json src/`                                                                                                                                           |
| tree-sitter CLI     | `tree-sitter --version`   | Multi-language full parse trees | `tree-sitter parse src/auth/handler.ts`                                                                                                                                                                             |
| TypeScript compiler | `tsc --version`           | TS/JS export extraction         | `tsc --declaration --emitDeclarationOnly --outDir /tmp/dts src/index.ts`                                                                                                                                            |
| Go toolchain        | `go version`              | Go package inspection           | `go doc ./src/auth/...`                                                                                                                                                                                             |
| Python ast          | `python3 -c "import ast"` | Python symbol extraction        | `python3 -c "import ast, json, sys; print(json.dumps([node.name for node in ast.parse(open(sys.argv[1]).read()).body if isinstance(node, (ast.FunctionDef, ast.ClassDef, ast.AsyncFunctionDef))]))" src/handler.py` |
| Rust analyzer       | `rust-analyzer --version` | Rust symbol and type info       | `cargo doc --document-private-items --no-deps`                                                                                                                                                                      |

## Dependency graph tools

Map inter-module relationships for project-level relationships.

| Tool           | Check                      | Best for                            | Example usage                            |
| -------------- | -------------------------- | ----------------------------------- | ---------------------------------------- |
| madge          | `npx madge --version`      | JS/TS import graphs                 | `npx madge --json src/`                  |
| dpdm           | `npx dpdm --version`       | JS/TS circular dependency detection | `npx dpdm --tree --json src/index.ts`    |
| depgraph (Go)  | `go version`               | Go package dependencies             | `go list -json ./...`                    |
| pipdeptree     | `pipdeptree --version`     | Python package dependencies         | `pipdeptree --json`                      |
| cargo-depgraph | `cargo depgraph --version` | Rust crate dependencies             | `cargo depgraph --dedup-transitive-deps` |

## Code analysis tools

Extract higher-level structural information like complexity, entry points, and dead code.

| Tool                    | Check                                                                            | Best for                                | Example usage                                                   |
| ----------------------- | -------------------------------------------------------------------------------- | --------------------------------------- | --------------------------------------------------------------- |
| ctags / universal-ctags | `ctags --version`                                                                | Multi-language symbol indexing          | `ctags -R --output-format=json --fields=+n src/`                |
| LSP                     | Check if `documentSymbol` or `goToDefinition` tools are available in the session | Definitions, references, call hierarchy | Use `goToDefinition`, `findReferences`, `documentSymbol`        |
| jq                      | `jq --version`                                                                   | Parsing JSON output from other tools    | `ast-grep --pattern 'export $$$' --json src/ \| jq '.[] .text'` |

LSP availability depends on the environment. In Claude Code, LSP tools (`documentSymbol`, `findReferences`, `goToDefinition`, `hover`, `incomingCalls`, `outgoingCalls`) are available automatically when a language server is running for the project. In other environments, check whether these tools exist in your tool list before attempting to use them. If LSP is unavailable, prefer ctags or ast-grep as alternatives for symbol and reference lookups.

## What to extract

Use whichever tools are available to pull the data you need. Examples:

| Category      | What to extract                                                 | Best tools                        |
| ------------- | --------------------------------------------------------------- | --------------------------------- |
| Files table   | List of files with their top-level symbols to infer purpose     | ctags, ast-grep, tree-sitter      |
| Key exports   | Exported functions, classes, types, constants — with signatures | tsc, ast-grep, go doc, Python ast |
| Relationships | Import statements → map which modules depend on which           | madge, go list, ast-grep          |
| Entry point   | File with the most inward references or the main/index file     | madge, LSP findReferences         |

## Fallback

If no external tools are available, fall back to reading source files directly and using LSP where available. The output should be identical regardless of method — external tools are accelerators, not requirements.
