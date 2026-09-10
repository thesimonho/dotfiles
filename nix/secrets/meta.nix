# Central registry for identities, public keys, and secret declarations.
# An identity groups everything needed for a git/SSH/GPG persona:
# email, SSH key, GPG config, and the remote URL pattern that activates it.

{
  # Age identity key — encrypts all secrets in this repo
  # Private key lives at ~/.secrets/age_identity (not managed by agenix — it IS the agenix decryption key)
  agePublicKey = "age1q78n6tyqujn6l4yvwvaa6m7p45z9lnl3cme79qf0curt6glfjdgq35nw9j";

  identities = {
    personal = {
      email = "simonho.ubc@gmail.com";
      sshKeyFile = "id_personal";
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInxAupJx0YQwBRFLN/gPQCc2my21GwU6CQet62Dww8y simonho.ubc@gmail.com";
      sshHost = "github.com";
      sshProxyHost = "ssh.github.com";
      sshPort = 443;
      remotePatterns = [
        "git@github.com:*/**"
        "https://github.com/**"
      ];
      gpg = {
        keyId = "241A482648245430";
        sign = true;
        secretFile = "gpg-personal";
        revocationFile = "gpg-personal-revocation";
        publicKey = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mDMEaqMi3xYJKwYBBAHaRw8BAQdAh0Xd7u/kuqGIB0W02ZuaxcY+CTkIssbpy60h
          ivtfxXC0IFNpbW9uIEhvIDxzaW1vbmhvLnViY0BnbWFpbC5jb20+iJYEExYKAD4W
          IQRrI6Sexu4Op+HLDXgkGkgmSCRUMAUCaqMi3wIbAwUJBaOagAULCQgHAgYVCgkI
          CwIEFgIDAQIeAQIXgAAKCRAkGkgmSCRUMMWFAQCemEGIUUQMCIZSwX1fHVK4wR1S
          ktcv1nTDgNXWVyUHJgD/UcTwe7X29zwiPk36PeZ7/ug3MLI0j2UL7NHc9VUE7AK4
          OARqoyLgEgorBgEEAZdVAQUBAQdAp4f7bu8moNZpONOpMKEqOCoG7mEKmJxEWN66
          amhOrmYDAQgHiH4EGBYKACYWIQRrI6Sexu4Op+HLDXgkGkgmSCRUMAUCaqMi4AIb
          DAUJBaOagAAKCRAkGkgmSCRUMEq2AP981YKsOsdrwQQyXeheLzlOxIBR4iUPj87Y
          ba/LNOoFewD9G2ncpyia/oRKSyzYBXYsg+m34J32stkDhVpTouByGA0=
          =uVpq
          -----END PGP PUBLIC KEY BLOCK-----
        '';
      };
    };
  };

  # Non-identity secrets
  # Each entry maps to a <file>.age in this directory, decrypted to ~/.secrets/<file>
  secrets = {
    api-keys = {
      file = "api-keys";
    };
  };
}
