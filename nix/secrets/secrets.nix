# Agenix secret declarations — declares which age public keys can decrypt each .age file.
# Consumed by the agenix CLI when encrypting/re-encrypting secrets.
let
  meta = import ./meta.nix;

  mkAgeEntry = filename: {
    name = "${filename}.age";
    value.publicKeys = [ meta.agePublicKey ];
  };

  sshEntries = builtins.map (id: mkAgeEntry id.sshKeyFile) (builtins.attrValues meta.identities);

  gpgEntries = builtins.concatMap (
    id:
    if id.gpg != null then
      (if id.gpg ? secretFile then [ (mkAgeEntry id.gpg.secretFile) ] else [ ])
      ++ (if id.gpg ? revocationFile then [ (mkAgeEntry id.gpg.revocationFile) ] else [ ])
    else
      [ ]
  ) (builtins.attrValues meta.identities);

  otherEntries = builtins.map (info: mkAgeEntry info.file) (builtins.attrValues meta.secrets);
in
builtins.listToAttrs (sshEntries ++ gpgEntries ++ otherEntries)
