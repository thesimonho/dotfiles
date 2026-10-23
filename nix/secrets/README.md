# Secret management

This directory contains age-encrypted credentials and their public identity registry.

KDE Linux uses fnox with the age identity held in KWallet's Secret Service under service `dotfiles-secrets`, account `age-identity`. `fnox.toml` contains encrypted global API values. The ordered `session-secrets` login service imports those values into the systemd and D-Bus activation environments before Plasma starts. Applications receive them when launched; restart an existing app to pick up changes. Project secrets remain project-owned.

SSH backups decrypt through a pipe into the existing OpenSSH agent. The askpass adapter preserves the original key-path prompt so ksshaskpass reuses its saved KWallet passphrase. SSH configuration selects the public key for agent matching. GPG backups stream into GnuPG during activation. The age identity and private SSH key are never exported into the session environment.

macOS and WSL retain agenix file deployment. The file-based instructions below apply to those platforms. KDE uses no plaintext-file fallback.

## How it works

All secrets are encrypted with a single **age identity key**. The private key (`age_identity`) is the root of trust — it decrypts everything else. The public key is committed to the repo in `meta.nix`.

Secrets fall into two categories:

- **Identity secrets** — SSH keys and GPG keys tied to a specific identity (defined in `meta.identities`)
- **Standalone secrets** — API keys and other credentials (defined in `meta.secrets`)

On non-KDE hosts, `home-manager switch` uses agenix to decrypt `.age` files and places them:

- Identity SSH keys → `~/.ssh/`
- Standalone secrets → `~/.secrets/`
- GPG private-key backups → streamed directly into GnuPG during activation
- GPG revocation certificates → remain encrypted; decrypt only for recovery

## File structure

```
secrets/
├── meta.nix                     # Source of truth — identities, public keys, secret declarations
├── secrets.nix                  # Agenix rule file (derived from meta.nix, consumed by agenix CLI)
├── id_personal.age              # Encrypted SSH key (personal identity)
├── gpg-personal.age             # Encrypted GPG private key (personal identity)
├── gpg-personal-revocation.age  # Encrypted GPG revocation cert (personal identity)
└── api-keys.age                 # Encrypted environment variables
```

**On a non-KDE machine after deployment:**

```
~/.secrets/
├── age_identity                 # Age private key (NOT managed by agenix — placed manually)
└── api-keys                     # Decrypted environment variables

~/.ssh/
├── id_personal                  # Decrypted SSH key
```

## KDE enrollment and use

Set up login unlocking for the `kdewallet` KWallet collection before running bootstrap from a KDE terminal. Bootstrap checks the wallet before Home Manager activation. If the age identity is present, it verifies that the identity matches `meta.nix` and continues without prompting. If it is absent, bootstrap asks for the age private key from Bitwarden with terminal echo disabled, validates its public recipient, stores it in KWallet, and verifies readback.

The key is never passed as an argument or written to a temporary file. Bootstrap refuses an incorrect key and does not replace an existing entry. A locked or unavailable wallet stops enrollment with instructions to unlock or configure it; bootstrap does not change PAM or wallet passwords. Retain the independent Bitwarden recovery copy.

You can rerun the same check after installation with `session-secrets enroll`. Hosts without selected credentials skip enrollment; macOS and WSL retain their file-based prerequisite. After activation, log out and in to verify `systemctl --user status session-secrets ssh-add-identities`.

Use `fnox set NAME` to edit global API values in a writable copy of `fnox.toml`, then commit only ciphertext. The deployed config is managed by Home Manager. Activation refreshes GPG's native key storage; `session-secrets decrypt /path/to/backup.age` writes plaintext to stdout and is intended only for a pipe into its consuming tool. Never redirect private credentials into persistent files.

A missing or unavailable wallet causes secret resolution to fail; no file fallback is used on KDE. Unit ordering permits desktop startup after a failure, so check the service status before assuming credentials are available.

## Setting up a non-KDE machine

1. **Restore the age identity key** from Bitwarden to `~/.secrets/age_identity`
2. **Clone dotfiles** and run `home-manager switch`

SSH keys and API keys are deployed automatically. GPG private keys are imported directly from their encrypted backups into GnuPG's native key storage; no decrypted export is retained in `~/.secrets/`. Public-key trust remains managed by Home Manager. A failed decrypt/import stops activation. The revocation certificate stays encrypted in this directory until recovery requires it.

## Rotating a compromised age identity

Treat loss of `~/.secrets/age_identity` as exposure of every secret encrypted to it. Git retains earlier ciphertext, so changing only `agePublicKey` and re-encrypting the same plaintext does not contain the incident: the old private identity can still decrypt the old revisions.

Use this order:

1. Revoke the SSH, GPG, API, and other credentials contained in every `.age` file.
2. Generate replacement credentials on a trusted machine.
3. Generate a new age identity with `age-keygen` and store its complete private identity in the password manager before deployment.
4. Replace `agePublicKey` in `meta.nix` with the new recipient.
5. Replace each secret's plaintext with its new credential and encrypt every `.age` file to the new recipient.
6. Confirm every tracked ciphertext decrypts with the new identity and fails with the old identity.
7. Build all affected host configurations before replacing the installed age identity.
8. Deploy the new private identity to trusted hosts, activate Home Manager, and verify authentication with the replacement credentials.
9. Remove old private keys from agents, keyrings, local files, and temporary rotation directories. Retain revoked public keys only when they are needed to verify historical signatures.

Never commit an age private identity, decrypted secret, API token, or key passphrase. Do not delete the last working copy of the old identity until the new ciphertext and its independently stored recovery copy are verified.

## Adding a new identity

Add an entry to `meta.identities` in `meta.nix`:

```nix
new-identity = {
  email = "you@example.com";
  sshKeyFile = "id_new";
  sshHost = "github.com";
  sshProxyHost = "ssh.github.com";
  sshPort = 443;
  remotePatterns = [ "git@github.com:*/**" "https://github.com/**" ];
  gpg = null;  # or { keyId = "..."; sign = true; publicKey = "..."; secretFile = "..."; revocationFile = "..."; };
};
```

Then encrypt the SSH key:

```bash
cd nix/secrets
agenix -e id_new.age
# Paste private key, save and quit
git add id_new.age meta.nix
```

SSH config, git identity routing, and secret decryption all derive from this one entry.

## Adding a standalone secret on non-KDE hosts

Add to `meta.secrets` in `meta.nix`:

```nix
new-service = {
  file = "new-service";
};
```

Then encrypt:

```bash
cd nix/secrets
agenix -e new-service.age
git add new-service.age meta.nix
```

## Cheat sheet

```bash
# Create/edit a secret
cd nix/secrets && agenix -e <name>.age

# Manual decryption (debugging)
agenix -d <name>.age -i ~/.secrets/age_identity

# Rebuild
home-manager switch

# Verify
ls -la ~/.ssh/id_*
ls -la ~/.secrets/
```
