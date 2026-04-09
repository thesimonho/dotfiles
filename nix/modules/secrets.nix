# Agenix secret decryption and age tooling.
# Reads secret declarations from secrets/meta.nix and decrypts them on activation.
# SSH keys → ~/.ssh/, everything else → ~/.secrets/
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

  # SSH keys get placed in ~/.ssh with strict permissions
  mkSshSecret = name: info: {
    name = name;
    value = {
      file = builtins.toPath "${../secrets}/${info.file}.age";
      path = "${sshDir}/${info.file}";
      mode = "600";
      symlink = false;
    };
  };
  sshSecrets = lib.mapAttrs' mkSshSecret (lib.filterAttrs (name: info: info.sshKey) meta.secrets);

  # Non-SSH secrets get placed in ~/.secrets
  mkOtherSecret = name: info: {
    name = name;
    value = {
      file = builtins.toPath "${../secrets}/${info.file}.age";
      path = "${secretsDir}/${info.file}";
      symlink = false;
    };
  };
  otherSecrets = lib.mapAttrs' mkOtherSecret (
    lib.filterAttrs (name: info: !info.sshKey) meta.secrets
  );
in
{
  home.packages = with pkgs; [
    age
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
  ];

  age = {
    identityPaths = [ "${sshDir}/ssh_identity" ];
    secrets = sshSecrets // otherSecrets;
  };
}
