---
agent:
  instruction: Keep script entry points and credential handling constraints current.
  on-change: "nix/scripts/**"
---

# Nix runtime scripts

These scripts are packaged by the Home Manager modules. Run the packaged commands so their declared tools and configuration are available.

`onepassword-check.sh`, run through `mise run onepassword-check` from `nix/`, checks the Arch CLI path, package permissions, Environment support and desktop authentication without printing vault contents. It rejects service-account, Connect and session-token overrides. Command success does not prove prompt usability, SSH signing or offline access.

When present, the native MCP helper also needs its `onepassword-mcp` group, setgid bit and PATH alias. AUR packaging has omitted this vendor setup, and upgrades can undo a local repair. The diagnostic detects missing integration; the vendor setup is `/opt/1Password/after-install.sh`.

`native-packages.py` reconciles native application packages; see [ownership and recovery](../README.md#native-packages). The game editor scripts connect project setup and file opening to the configured editor. `write-skills-readme.sh` generates the installed skill index.

Credential delivery uses `with-secrets` from `nix/modules/onepassword.nix`. Keep private values out of arguments, logs, persistent staging files and exception messages.
