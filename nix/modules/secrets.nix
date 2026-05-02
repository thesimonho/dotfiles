# Agenix secret decryption and age tooling.
# Reads from secrets/meta.nix and decrypts secrets on activation.
# Identity SSH keys → ~/.ssh/, GPG secret keys → ~/.secrets/, other secrets → ~/.secrets/
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  sshDir = "${config.home.homeDirectory}/.ssh";
  secretsDir = "${config.home.homeDirectory}/.secrets";
  meta = import ../secrets/meta.nix;

  selectedIdentities = lib.filterAttrs (name: _: lib.elem name config.my.identities) meta.identities;
  selectedSecrets = lib.filterAttrs (name: _: lib.elem name config.my.secrets) meta.secrets;

  # SSH keys from identities → ~/.ssh/
  sshSecrets = lib.mapAttrs' (name: id: {
    name = "identity-ssh-${name}";
    value = {
      file = builtins.toPath "${../secrets}/${id.sshKeyFile}.age";
      path = "${sshDir}/${id.sshKeyFile}";
      mode = "600";
      symlink = false;
    };
  }) selectedIdentities;

  # GPG secrets from identities → ~/.secrets/
  gpgKeySecrets = lib.mapAttrs' (name: id: {
    name = "identity-gpg-key-${name}";
    value = {
      file = builtins.toPath "${../secrets}/${id.gpg.secretFile}.age";
      path = "${secretsDir}/${id.gpg.secretFile}";
      mode = "600";
      symlink = false;
    };
  }) (lib.filterAttrs (name: id: id.gpg != null && id.gpg ? secretFile) selectedIdentities);

  gpgRevocationSecrets = lib.mapAttrs' (name: id: {
    name = "identity-gpg-rev-${name}";
    value = {
      file = builtins.toPath "${../secrets}/${id.gpg.revocationFile}.age";
      path = "${secretsDir}/${id.gpg.revocationFile}";
      mode = "600";
      symlink = false;
    };
  }) (lib.filterAttrs (name: id: id.gpg != null && id.gpg ? revocationFile) selectedIdentities);

  # Non-identity secrets → ~/.secrets/
  otherSecrets = lib.mapAttrs' (name: info: {
    name = name;
    value = {
      file = builtins.toPath "${../secrets}/${info.file}.age";
      path = "${secretsDir}/${info.file}";
      symlink = false;
    };
  }) selectedSecrets;
in
{
  home.packages = with pkgs; [
    age
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
  ];

  age = {
    identityPaths = [ "${secretsDir}/age_identity" ];
    secrets = sshSecrets // gpgKeySecrets // gpgRevocationSecrets // otherSecrets;
  };
}
