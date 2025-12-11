let meta = import ./meta.nix;
in {
  "ssh-personal.age".publicKeys = [ meta.personal.publicKey ];
  "ssh-sprung.age".publicKeys = [ meta.sprung.publicKey ];
}

