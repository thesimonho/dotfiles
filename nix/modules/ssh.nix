{ config, pkgs, lib, ... }:

{
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
        forwardX11 = true;
        forwardX11Trusted = true;
        identitiesOnly = true;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519_sprung";
      };
      "personal-github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        addKeysToAgent = "true";
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
        identitiesOnly = true;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
    };
  };
}
