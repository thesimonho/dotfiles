# Central registry for public keys and secret declarations.
# Public keys are safe to commit — they're used for encryption and identity, not decryption.
# Secrets map to .age files in this directory; ssh.nix handles decryption via agenix.

{
  publicKeys = {
    # Age identity key — encrypts all secrets in this repo (derived from ssh_identity.pub)
    age = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa8Ec2tSLTEmmMfJw/qF2rNRycb7wm1Pxls2qr3AbPF";

    # GPG key ID — used for git commit signing
    gpgKeyId = "1A3DBCCFA37493B1";

    # GPG public key — imported into the keyring by gpg.nix
    gpg = ''
      -----BEGIN PGP PUBLIC KEY BLOCK-----

      mDMEaddVoBYJKwYBBAHaRw8BAQdAzzRMmBYWLrlIqboKz906cTe2T4VJn38KLxQq
      kc+LXB20IFNpbW9uIEhvIDxzaW1vbmhvLnViY0BnbWFpbC5jb20+iJYEExYKAD4W
      IQTfC1UXKqlBUTMAdaUaPbzPo3STsQUCaddVoAIbAwUJBaOagAULCQgHAgYVCgkI
      CwIEFgIDAQIeAQIXgAAKCRAaPbzPo3STsQWqAP4tPuqb2KkPKgrHT44xl0eNURMh
      HlFS5OcPhvombxEXqwEAx8RxI2nF8diU42T2oWgqhzf6cMad4iso/VREReCs9gC4
      OARp11WgEgorBgEEAZdVAQUBAQdAbCczKPOFibLTshbkOPmsfcK0Z9jk70+AfFe7
      7iSdqygDAQgHiH4EGBYKACYWIQTfC1UXKqlBUTMAdaUaPbzPo3STsQUCaddVoAIb
      DAUJBaOagAAKCRAaPbzPo3STsVw3AP41HTRYfucbsduKz/SSuq7r9EOqLJUwHzSU
      QXVHFL1/QAD+P4R8kiolEElfHW188QtRNAqLYiZHXHnHTtBqI82sxQI=
      =MWi+
      -----END PGP PUBLIC KEY BLOCK-----
    '';
  };

  # Each entry maps to a <file>.age in this directory.
  # sshKey = true  → decrypted to ~/.ssh/<file>
  # sshKey = false → decrypted to ~/.secrets/<file>
  secrets = {
    api-keys = {
      file = "api-keys";
      sshKey = false;
    };
    gpg-secret = {
      file = "gpg-secret";
      sshKey = false;
    };
    gpg-revocation = {
      file = "gpg-revocation";
      sshKey = false;
    };
    personal = {
      file = "id_personal";
      sshKey = true;
    };
    sprung = {
      file = "id_sprung";
      sshKey = true;
    };
  };
}
