let meta = import ./meta.nix;
in {
  "id_personal.age".publicKeys = [ meta.personal.publicKey ];
  "id_sprung.age".publicKeys = [ meta.sprung.publicKey ];
}

