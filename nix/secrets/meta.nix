# Add new secrets/key here to be decrypted by age
# Every secret uses the same public key (ssh-identity)

{
  # from ssh_identity.pub
  identityKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa8Ec2tSLTEmmMfJw/qF2rNRycb7wm1Pxls2qr3AbPF";

  secrets = {
    personal = {
      file = "id_personal";
      sshKey = true; # Mark as SSH key to place in ~/.ssh
    };
    sprung = {
      file = "id_sprung";
      sshKey = true;
    };
    api-keys = {
      file = "api-keys";
      sshKey = false; # Not an SSH key
    };
  };
}
