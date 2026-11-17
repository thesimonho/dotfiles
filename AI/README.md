---
agent:
  instruction: Keep the secret-reference documentation current when the launcher mappings change.
  on-change:
    - nix/lib/catalog.nix
    - nix/modules/apps/catalog.nix
    - nix/modules/ai/catalog.nix
    - nix/scripts/with-secrets.py
    - nix/modules/onepassword.nix
---

# AI configuration

This directory contains agent instructions, settings, skills, hooks, scripts, and evaluation cases. Subdirectories document their own conventions.

## Catalog-managed 1Password secrets

Secret references belong to their owning application in the Nix catalogs. `secrets.provides` maps environment names to `op://` references; values remain in 1Password. Applications automatically receive their own provided secrets. `secrets.requires` imports providers by qualified catalog name or groups through `vault.NAME`. Imported providers contribute only their own references, not their requirements.

`my.onepassword.vaults.models` contains OpenAI (Codex) and TypeSafe. `developer-tools` contains GitHub, Hugging Face, and Cloudflare. These are Nix access groups, distinct from 1Password vaults. Conflicting variable definitions and unknown references fail evaluation. Rename references when a 1Password vault, item, or field name changes.

A catalog `command` gives the absolute real executable. Nix generates a higher-priority wrapper under the same binary name for applications with secrets. Desktop entries and actions use the same application's generated launcher. Normal commands and menu entries therefore work for users and agents. Native macOS Dock/Finder injection is not implemented.

Launchers reuse nonempty inherited values and fetch only missing or unresolved values through official `op run`. Interactive launches disable output masking to preserve terminal behavior; never print credentials. No shell plugins or marker are used. Fresh manual invocations may prompt separately. A long-lived IDE/agent receives its groups at launch and passes them to local descendants without more retrieval. Fully quit apps to pick up rotations; locking 1Password does not revoke existing copies. VM, remote, and isolated runtimes need separate verification.

`with-secrets COMMAND [ARG...]` is an optional manual launcher for the combined configured vaults. Agents should run commands normally. The handwritten `AI/secrets.env` and Environment-ID helper interface are retired.
