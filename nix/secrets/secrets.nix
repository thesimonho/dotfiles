let
  meta = import ./meta.nix;

  mkAgeEntry = name: info: {
    name = "${info.file}.age";
    value.publicKeys = [ meta.identityKey ];
  };
in
builtins.listToAttrs (builtins.attrValues (builtins.mapAttrs mkAgeEntry meta.secrets))
