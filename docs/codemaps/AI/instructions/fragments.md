---
agent:
  instruction: Update this codemap when instruction fragments are added, removed, or change responsibility.
  on-change: "AI/instructions/fragments/**"
---

# AI Instruction Fragments

Source-of-truth Markdown sections assembled into generated agent instruction files. Each fragment owns one policy domain so host-specific generators can reuse the same guidance.

## Files

| File | Description |
| --- | --- |
| `coding-style.md` | Readable naming, small-file organization, function shape, and comment guidance |
| `documentation.md` | Documentation lifecycle, codemap use, and file-scoped agent frontmatter |
| `git.md` | Branching, conventional commits, focused commits, and merge requirements |
| `images.md` | Repository and temporary storage rules for generated images |
| `planning.md` | Plan review, filename, HTML structure, and dependency research rules |
| `security.md` | Mandatory checks and the stop-and-escalate response protocol |
| `subagents.md` | Delegation criteria and model tiers |
| `tools.md` | Just, RTK, LSP, structural search, data parsing, browser, and codemap guidance |
| `workflow.md` | Scope discipline, TDD/debugging guidance, verification, and response ordering |

## Relationships

- **Used by**: `nix/modules/ai/instructions.nix`, which combines fragments for configured agent clients.
- **Produces**: generated instruction surfaces such as `AI/instructions/AGENTS.generated.md`.

## Entry point

Start with the fragment matching the policy domain being changed; inspect `nix/modules/ai/instructions.nix` to see how it reaches each client.
