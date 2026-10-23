---
agent:
  instruction: Keep script entry points and credential handling constraints current.
  on-change: "nix/scripts/**"
---

# Nix runtime scripts

These scripts are packaged by the Home Manager modules. Run the packaged commands so their declared tools and configuration are available.

`native-packages.py` reconciles native application packages. Its ownership and recovery rules are documented in `nix/README.md`. The game editor scripts connect project setup and file opening to the configured editor. `write-skills-readme.sh` generates the installed skill index.

`session-secrets.py` is the shared native-keyring credential adapter, packaged as `session-secrets` by `nix/modules/secrets.nix`. Bootstrap also runs its `enroll` action before profile activation to check or privately enroll the age identity in the native store. Its KDE backend imports only declared global API values into the desktop activation environment and streams encrypted backups to SSH or GPG. The separate identity config is for explicit key lookup only; never merge it into the exported global secret inventory. Keep credentials out of command arguments, persistent temporary files, logs, and exception messages. Recovery enrollment is documented in `nix/secrets/README.md`.

The macOS adapter is runtime-unverified; it uses a Security-framework metadata lookup for enrollment and fnox for credential access. Unsupported platforms fail before activation. Desktop environment import is KDE-only; do not turn missing platform capabilities into plaintext fallbacks.
