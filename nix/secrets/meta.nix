# Add new secrets/key here to be decrypted by age
# Every secret uses the same public key (ssh-identity)

{
  personal = {
    file = "id_personal";
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa8Ec2tSLTEmmMfJw/qF2rNRycb7wm1Pxls2qr3AbPF";
  };
  sprung = {
    file = "id_sprung";
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMa8Ec2tSLTEmmMfJw/qF2rNRycb7wm1Pxls2qr3AbPF";
  };
}
