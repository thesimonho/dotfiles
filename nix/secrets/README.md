---
agent:
  instruction: Keep supported secret capabilities and native-store enrollment instructions current.
  on-change:
    [
      "nix/modules/secrets.nix",
      "nix/modules/gpg.nix",
      "nix/modules/ssh.nix",
      "nix/scripts/session-secrets.py",
      "nix/bootstrap.sh",
    ]
---

# Secret management

All hosts use one model: an age identity in a native credential store, encrypted API values in `fnox.toml`, and encrypted SSH/GPG backups. No plaintext secret directory or private SSH file is deployed. Keep the complete age identity in Bitwarden as the independent recovery copy.

| Platform               | Native storage                                          | Available delivery                                                                                                                                                       |
| ---------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| KDE Linux              | KWallet Secret Service, unlocked `kdewallet` collection | Verified enrollment, global desktop API environment, SSH-agent loading, and GPG import.                                                                                  |
| macOS                  | Login Keychain through fnox                             | Enrollment/retrieval adapter, streamed GPG import and manual terminal SSH loading are implemented but runtime-unverified. Automatic desktop API delivery is unavailable. |
| WSL and other desktops | No implemented adapter                                  | Credential-bearing bootstrap and activation stop explicitly. No file fallback.                                                                                           |

## Enrollment

Run bootstrap from an interactive terminal. On KDE, configure KWallet login unlocking and enable its Secret Service API first. On macOS, the login Keychain must be available; native access consent may be required. Bootstrap and `mise run switch` run `session-secrets enroll` before activation. You can also run that command directly after installation.

Enrollment checks service `dotfiles-secrets`, account `age-identity`. An existing identity is checked against the public recipient in `meta.nix` and skips prompting. An absent identity triggers a hidden terminal prompt; the identity is validated before storage and checked again after readback. Access errors are not treated as missing entries, and existing entries are not replaced. Temporary enrollment config contains only references; the private key passes over stdin and is never staged in a file.

KDE's ordered `session-secrets` service imports only declared API values into systemd and D-Bus activation environments before Plasma starts. Restart existing applications to receive changes. SSH keys stream into the OpenSSH agent; the askpass adapter preserves the original path prompt to reuse KWallet's saved passphrase. GPG imports stream into native GnuPG storage during activation. Revocation backups stay encrypted until needed for recovery.

On macOS, use `fnox exec -- COMMAND` to provide API values to explicit terminal commands, and `session-secrets ssh` from a terminal to load SSH keys into the session agent. SSH passphrase persistence, login loading, Keychain consent and GUI API delivery have not been verified on hardware. `session-secrets environment` reports the unavailable desktop delivery capability instead of silently substituting shell sourcing. No launch agent is installed for these operations.

## Files and maintenance

- `meta.nix`: public recipient, identity public keys, Git routing, and selected secret groups.
- `fnox.toml`: age-encrypted global API entries; the keychain-held identity is a provider dependency, never an exported secret.
- `id_personal.age`: encrypted SSH backup.
- `gpg-personal.age`: encrypted GPG backup.
- `gpg-personal-revocation.age`: encrypted revocation backup.

Edit API values with `fnox set NAME` in a writable copy of `fnox.toml`, then commit only ciphertext. Home Manager manages the deployed config. Individual project secrets remain project-owned.

For a new identity, add its public metadata to `meta.identities` and encrypt its backup with `age --recipient RECIPIENT --output KEY.age`, reading private data from stdin or a secure source. Use the public recipient from `meta.nix`; do not pass private values as arguments. `session-secrets decrypt /path/to/backup.age` writes plaintext to stdout and is intended for a pipe into its consuming tool. Never redirect private credentials into persistent staging files.

## Recovery and rotation

Recover a lost keychain entry by rerunning enrollment with the identity from Bitwarden. Retain that independent recovery copy. Changing the public recipient alone does not contain exposure of an old private identity: Git history retains ciphertext decryptable by it. A compromised identity requires revoking/replacing the encrypted credentials, creating a new age identity and independent recovery copy, re-encrypting backups and fnox values, and verifying the replacements before retiring old keys. Do not delete the last working identity until the independent recovery copy and new ciphertext are verified.
