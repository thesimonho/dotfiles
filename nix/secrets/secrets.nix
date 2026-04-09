# Agenix secret declarations — maps meta.nix secrets to .age files.
# Each secret is encrypted to the age identity key so agenix can decrypt on activation.
let
  meta = import ./meta.nix;

  mkAgeEntry = name: info: {
    name = "${info.file}.age";
    value.publicKeys = [ meta.publicKeys.age ];
  };
in
builtins.listToAttrs (builtins.attrValues (builtins.mapAttrs mkAgeEntry meta.secrets))
