# Secret Management with agenix

This directory contains encrypted secrets managed by **agenix** and **Nix/Home Manager**, using a single age identity key for decryption.

## How it works

All secrets are encrypted with a single **age identity key**. The private key (`age_identity`) is the root of trust — it decrypts everything else. The public key is committed to the repo in `meta.nix`.

Secrets fall into two categories:

- **Identity secrets** — SSH keys and GPG keys tied to a specific identity (defined in `meta.identities`)
- **Standalone secrets** — API keys and other credentials (defined in `meta.secrets`)

On `home-manager switch`, agenix decrypts `.age` files and places them:

- Identity SSH keys → `~/.ssh/`
- Everything else → `~/.secrets/`

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

**On machine after deployment:**

```
~/.secrets/
├── age_identity                 # Age private key (NOT managed by agenix — placed manually)
├── gpg-personal                 # Decrypted GPG private key
├── gpg-personal-revocation      # Decrypted GPG revocation cert
└── api-keys                     # Decrypted environment variables

~/.ssh/
├── id_personal                  # Decrypted SSH key
```

## Setting up a new machine

1. **Restore the age identity key** from Bitwarden to `~/.secrets/age_identity`
2. **Clone dotfiles** and run `home-manager switch`

That's it. All SSH keys, GPG keys, and API keys are decrypted automatically.

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

## Adding a standalone secret

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
