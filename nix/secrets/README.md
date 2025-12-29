# SSH Key & Secret Management with agenix

This directory contains everything required to **securely store, encrypt, and deploy SSH private keys and API keys** using **agenix** and **Nix/Home Manager**, using a **single identity keypair** for decryption.

The goals of this setup:

- Store **encrypted secrets** in the repo (safe to commit)
- Never commit plaintext private keys or API keys
- Distribute secrets automatically through Nix
- Bootstrap new machines easily
- Use **one identity keypair** to decrypt all secrets
- Keep actual SSH keys and API keys as _payload_ secrets

---

## Overview

### What is an identity key?

The **identity keypair** is the key that agenix uses to decrypt secrets.

It is **not** one of the SSH "payload" keys.
It is a dedicated keypair whose:

- **public key** goes into `meta.nix` as `identityKey`
- **private key** sits on the machine at `~/.ssh/ssh_identity`

Think of it as the master key that unlocks all `.age` files.

### What are payload secrets?

These are the real secrets you want to deploy:

**SSH keys:**

- `id_personal`
- `id_sprung`

**API keys and environment variables:**

- `api-keys` (contains GITHUB_TOKEN, OPENAI_API_KEY, etc.)

Each of these becomes an encrypted file (e.g., `id_personal.age`, `api-keys.age`).

They **do not decrypt themselves**.
They are just _data_ encrypted using the **identity public key**.

---

## 1. Generate the identity keypair (one-time setup)

Run:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ssh_identity -C "agenix-identity"
```

This creates:

```
~/.ssh/ssh_identity          ← identity private key (KEEP SECRET, never commit)
~/.ssh/ssh_identity.pub      ← identity public key (used in meta.nix)
```

Copy the public key content:

```bash
cat ~/.ssh/ssh_identity.pub
```

Use this value as `identityKey` in `meta.nix`.

---

## 2. Define secrets in `meta.nix`

This is the **single source of truth** for all secrets:

```nix
{
  # Identity public key (from ssh_identity.pub)
  identityKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa8Ec2tSLTEmmMfJw/qF2rNRycb7wm1Pxls2qr3AbPF";

  # All secrets defined once
  secrets = {
    personal = {
      file = "id_personal";
      sshKey = true;  # Will be placed in ~/.ssh/
    };

    sprung = {
      file = "id_sprung";
      sshKey = true;
    };

    api-keys = {
      file = "api-keys";
      sshKey = false;  # Will be placed in ~/.secrets/
    };
  };
}
```

**Key points:**

- All secrets use the **same** `identityKey` for encryption
- `sshKey = true` → decrypts to `~/.ssh/`
- `sshKey = false` → decrypts to `~/.secrets/`

---

## 3. Create or edit secrets

### Prerequisites

Make sure the `agenix` CLI is installed. It's included in the home-manager config via:

```nix
home.packages = [
  inputs.agenix.packages.${stdenv.hostPlatform.system}.default
];
```

After running `home-manager switch`, the `agenix` command will be available.

### Creating/editing secrets

**From the `secrets/` directory:**

```bash
cd nix/secrets
```

**For SSH private keys:**

```bash
# Create or edit an SSH key
agenix -e id_personal.age
```

In the editor, paste the **private key**:

```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

Save and quit → agenix encrypts using the identity public key.

**For API keys and environment variables:**

```bash
# Create or edit API keys
agenix -e api-keys.age
```

In the editor, add key-value pairs (plain format, no `export`):

```
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxx
DATABASE_URL=postgres://user:pass@localhost/db
```

Save and quit → agenix encrypts the file.

### Important: Git add the encrypted files

**Nix flakes only see git-tracked files!** Don't forget:

```bash
git add *.age
git commit -m "Update secrets"
```

---

## 4. Deploy secrets

After creating/editing secrets:

```bash
home-manager switch
```

Agenix will:

- Use `~/.ssh/ssh_identity` to decrypt all `.age` files
- Write SSH keys to `~/.ssh/` with mode 600
- Write other secrets to `~/.secrets/`
- Load API keys automatically in new terminal sessions (via zsh)

**Verify:**

```bash
# Check SSH keys
ls -la ~/.ssh/id_*

# Check API keys
ls -la ~/.secrets/
cat ~/.secrets/api-keys

# Check environment variables (open new terminal)
echo $GITHUB_TOKEN
```

---

## 5. Setting up a new machine

To set up secrets on a new machine:

### Step 1: Install the identity private key

Copy then identity key to the new machine **once**:

```bash
# From existing machine
scp ~/.ssh/ssh_identity newmachine:~/.ssh/
scp ~/.ssh/ssh_identity.pub newmachine:~/.ssh/

# On the new machine
chmod 600 ~/.ssh/ssh_identity
chmod 644 ~/.ssh/ssh_identity.pub
```

⚠️ **Security note:** Transfer this securely (USB drive, direct SCP, etc.). Never commit it to git!

### Step 2: Clone dotfiles

```bash
git clone https://github.com/thesimonho/dotfiles.git ~/dotfiles
cd ~/dotfiles/nix
```

### Step 3: Build

```bash
home-manager switch
```

All SSH keys and API keys will be automatically decrypted and placed correctly.

---

## 6. Adding a new secret

### For a new SSH key

1. Generate it:

```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_new
```

1. Add to `meta.nix`:

```nix
   new = {
     file = "id_new";
     sshKey = true;
   };
```

1. Encrypt the private key:

```bash
   cd nix/secrets
   agenix -e id_new.age
   # Paste the private key content, save and quit
```

1. Git add and rebuild:

```bash
   git add id_new.age meta.nix
   git commit -m "Add new SSH key"
   home-manager switch
```

### For a new API key or environment variable

1. Add to `meta.nix` (if creating a new secret file):

```nix
   new-service = {
     file = "new-service";
     sshKey = false;
   };
```

1. Edit the secret:

```bash
   cd nix/secrets
   agenix -e api-keys.age  # Or agenix -e new-service.age
   # Add KEY=value pairs
```

1. Git add and rebuild:

```bash
   git add api-keys.age  # Or new-service.age
   git commit -m "Update API keys"
   home-manager switch
```

1. Open a new terminal to load the new environment variables.

---

## 7. File structure

```
secrets/
├── meta.nix              # Single source of truth - defines all secrets
├── secrets.nix           # Auto-generated from meta.nix (tells agenix which keys to use)
├── id_personal.age       # Encrypted SSH private key
├── id_sprung.age         # Encrypted SSH private key
└── api-keys.age          # Encrypted environment variables
```

**On machine after deployment:**

```
~/.ssh/
├── ssh_identity          # Identity private key (decrypts .age files)
├── ssh_identity.pub      # Identity public key
├── id_personal           # Decrypted SSH key
└── id_sprung             # Decrypted SSH key

~/.secrets/
└── api-keys              # Decrypted environment variables
```

---

## 8. Why this system is secure and convenient

✅ Only machines with the **identity private key** can decrypt secrets  
✅ All sensitive keys/tokens appear only at runtime, never in git  
✅ New machines require a single bootstrap step (copying identity key)  
✅ Secrets are declared once in `meta.nix` and deployed everywhere  
✅ `.age` files are safe to commit and sync  
✅ No more copying SSH private keys or API keys manually  
✅ Single source of truth - add a secret once, it's available everywhere  
✅ Type-safe separation - SSH keys go to `~/.ssh/`, API keys to `~/.secrets/`

---

## Cheat Sheet

### Create/edit a secret

```bash
cd nix/secrets
agenix -e <name>.age
```

### Add new secret to config

1. Edit `meta.nix` (add entry to `secrets` object)
2. Create/edit the `.age` file with `agenix -e`
3. **Don't forget:** `git add *.age meta.nix`
4. Rebuild: `home-manager switch`

### View identity public key

```bash
cat ~/.ssh/ssh_identity.pub
```

### Manual decryption (for debugging)

```bash
agenix -d <name>.age -i ~/.ssh/ssh_identity
```

### Check if secrets are loaded

```bash
# SSH keys
ls -la ~/.ssh/id_*

# API keys
cat ~/.secrets/api-keys

# Environment variables (in new terminal)
env | grep -E "GITHUB|OPENAI|ANTHROPIC"
```
