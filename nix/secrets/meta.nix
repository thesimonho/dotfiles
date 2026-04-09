# Central registry for identities, public keys, and secret declarations.
# An identity groups everything needed for a git/SSH/GPG persona:
# email, SSH key, GPG config, and the remote URL pattern that activates it.

{
  # Age identity key — encrypts all secrets in this repo
  # Private key lives at ~/.secrets/age_identity (not managed by agenix — it IS the agenix decryption key)
  agePublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa8Ec2tSLTEmmMfJw/qF2rNRycb7wm1Pxls2qr3AbPF";

  identities = {
    personal = {
      email = "simonho.ubc@gmail.com";
      sshKeyFile = "id_personal";
      sshHost = "github.com";
      sshProxyHost = "ssh.github.com";
      sshPort = 443;
      remotePattern = "git@github.com:*/**";
      gpg = {
        keyId = "1A3DBCCFA37493B1";
        sign = true;
        secretFile = "gpg-personal";
        revocationFile = "gpg-personal-revocation";
        publicKey = ''
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
    };
    sprung = {
      email = "simon@sprungstudios.com";
      sshKeyFile = "id_sprung";
      sshHost = "work-github.com";
      sshProxyHost = "ssh.github.com";
      sshPort = 443;
      remotePattern = "git@work-github.com:*/**";
      gpg = null;
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
