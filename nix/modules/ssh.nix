{ config, pkgs, lib, ... }:

let
  sshDir = "${config.home.homeDirectory}/.ssh";
  meta = import ../secrets/meta.nix;

  mkSecret = name: item: {
    # Attribute name: "ssh-personal" etc
    name = "${name}";
    value = {
      file = builtins.toPath "${../secrets}/${item.file}.age";
      path = "${sshDir}/${item.file}";
      mode = "600";
      symlink = false;
    };
  };
in {
  home = { packages = with pkgs; [ age ]; };
  # add yubikey support https://github.com/oddlama/agenix-rekey
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        addKeysToAgent = "true";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = "${sshDir}/${meta.sprung.file}";
      };
      "personal-github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        addKeysToAgent = "true";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = "${sshDir}/${meta.personal.file}";
      };
    };
  };
  age = {
    identityPaths = [ "${sshDir}/ssh-identity" ];
    secrets = lib.mapAttrs' mkSecret meta;
  };
}
