---
agent:
  instruction: Update this codemap when Nix setup and diagnostic scripts change.
  on-change: "nix/scripts/**"
---

# Nix Scripts

Operational shell scripts used during setup and diagnosis of skills, secrets, SSH keys, and GPG signing.

## Files

| File group | Description |
| --- | --- |
| `doctor-*.sh` | Checks skills and secret setup, with shared human-readable output helpers |
| `describe-skills.sh` | Reports resolved skills and their source/install state |
| `write-skills-readme.sh` | Generates the installed-skills summary consumed by users and agents |
| `ssh-*.sh` | Resolves configured SSH keys and adds them to the running agent |
| `gpg-*.sh` | Imports keys and configures preset passphrases for signing |
| `secret-askpass.sh` | Supplies secret-backed credentials through a constrained askpass interface |

## Relationships

- **Used by**: activation hooks and recipes in `nix/justfile` and Nix modules.
- **Reads**: Home Manager environment and secret material provisioned by `nix/modules/secrets.nix`.

## Entry point

Start with the matching `doctor-*` script for diagnosis; follow its calls into the corresponding setup script.
