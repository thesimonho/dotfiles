# Agenix secret decryption and age tooling.
# Reads from secrets/meta.nix and decrypts secrets on activation.
# Identity SSH keys → ~/.ssh/, other secrets → ~/.secrets/
# GPG backups are imported directly by gpg.nix; revocation backups stay encrypted.
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
  selectedIdentities = config.my._identities;
  selectedSecrets = config.my._secrets;

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
    secrets = sshSecrets // otherSecrets;
  };
}
