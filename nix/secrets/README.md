# SSH Key Management with agenix

This directory contains everything required to **securely store, encrypt, and deploy SSH private keys** using **agenix** and **Nix/Home Manager**, using a **single identity keypair** for decryption.

The goals of this setup:

- Store **encrypted private keys** in the repo (safe to commit)
- Never commit plain SSH private keys
- Distribute secrets automatically through Nix
- Bootstrap new machines easily
- Use **one identity keypair** to decrypt all secrets
- Keep your actual SSH keys (personal/work/etc.) as _payload_ secrets

---

## Overview

### What is an identity key?

The **identity keypair** is the key that agenix uses to decrypt secrets.

It is **not** one of your SSH “payload” keys.
It is a dedicated keypair whose:

- **public key** goes into `meta.nix` as the encryption recipient
- **private key** sits on your machine and is referenced in `age.identityPaths`

Think of it as the master key that unlocks all `.age` files.

### What are payload keys?

These are your real SSH private keys you want to deploy:

- `id_personal`
- `id_work`
- etc.

Each of these becomes an encrypted file:

```
id_personal.age
id_work.age
```

They **do not decrypt themselves**.
They are just _data_ encrypted using your **identity public key**.

---

# 1. Generate the identity keypair

Run:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ssh_identity -C "agenix-identity"
```

This creates:

```
~/.ssh/ssh_identity          ← identity private key (KEEP SECRET)
~/.ssh/ssh_identity.pub      ← identity public key (safe to commit)
```

Use the public key (`ssh_identity.pub`) in `meta.nix`.

---

# 2. Define your secrets in `meta.nix`

Example:

```nix
{
  personal = {
    file = "id_personal";                  # encrypted file name (personal.age)
    publicKey = "ssh-ed25519 AAAA… agenix-identity";
  };

  work = {
    file = "id_work";
    publicKey = "ssh-ed25519 AAAA… agenix-identity";
  };
}
```

Every entry uses the **same** `publicKey`—the identity public key.

---

# 3. Create or edit secrets (the payload SSH private keys)

To add or modify a secret:

```bash
nix run github:ryantm/agenix -- -e secrets/id_personal.age
```

Paste the **payload private key**, for example:

```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

Save → agenix encrypts using the identity public key.

Repeat for:

```bash
nix run github:ryantm/agenix -- -e secrets/id_work.age
```

These `.age` files **are safe to commit**.

---

# 4. Home Manager configuration

Example HM module:

```nix
let
  sshDir = "${config.home.homeDirectory}/.ssh";
  meta = import ../secrets/meta.nix;

  mkSecret = name: item: {
    name = "id_${name}";
    value = {
      file = ../secrets/"${item.file}.age";
      path = "${sshDir}/${item.target}";
      mode = "600";
      symlink = false;
    };
  };
in {
  age = {
    # The identity private key used to decrypt all secrets
    identityPaths = [ "${sshDir}/ssh_identity" ];

    # Generate one age.secrets.* entry per payload key
    secrets = lib.mapAttrs' mkSecret meta;
  };
}
```

When you run:

```bash
home-manager switch
```

Agenix will:

- use `ssh_identity` to decrypt all `.age` files
- write them to `~/.ssh/<target>`

Example results:

```
~/.ssh/id_personal
~/.ssh/id_work
```

---

# 5. Setting up a new machine

To authorize a new machine, you must install the **identity private key** on it **once**:

1. Copy the identity key:

```bash
scp ~/.ssh/ssh_identity newmachine:~/.ssh/
chmod 600 ~/.ssh/ssh_identity
```

1. Clone your dotfiles and run:

```bash
home-manager switch
```

Boom — all payload SSH keys appear automatically.

You **never** manually copy the personal/work private keys again.

---

# 6. Adding a new SSH key later

1. Generate it normally:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_new
```

1. Add a new entry to `meta.nix`:

```nix
new = {
  file = "id_new";
  publicKey = "ssh-ed25519 AAAA… agenix-identity";
};
```

1. Create the secret (run from the secrets directory):

```bash
nix run github:ryantm/agenix -- --identity ~/.ssh/ssh_identity -e new.age
```

1. Rebuild:

```bash
home-manager switch
```

The new key now appears on every machine with `ssh_identity`.

---

# 7. Why this system is secure and convenient

- Only machines with the **identity private key** can decrypt secrets
- All sensitive payload private keys appear only at runtime, never in git
- New machines require a single bootstrap step
- Secrets are declared once and deployed everywhere
- `.age` files are safe to commit and sync
- No more copying SSH private keys manually

---

# Cheat Sheet

### Create/edit a secret

```
agenix -e secrets/<name>.age
```

### Rebuild

```
home-manager switch
```

### Show your identity public key

```
cat ~/.ssh/ssh_identity.pub
```
