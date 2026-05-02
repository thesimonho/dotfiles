{ config, lib, ... }:

{
  my = {
    os = lib.mkDefault "darwin";
    desktop = lib.mkDefault "none";
    gpu.backend = lib.mkDefault "metal";
    identities = lib.mkDefault [
      "personal"
      "sprung"
    ];
    secrets = lib.mkDefault [ "api-keys" ];
    apps = {
      bundles = lib.mkDefault [
        "baseline"
        "security-tools"
        "fonts"
        "cloud"
      ];
      enabled = lib.mkDefault [ "slack-darwin" ];
    };
    ai = {
      bundles = lib.mkDefault [
        "cli-agents"
        "tooling"
        "local-models"
      ];
      claude.targetDir = lib.mkDefault ".claude2";
    };
  };

  home = {
    username = lib.mkDefault "simon.ho";
    homeDirectory = lib.mkDefault "/Users/simon.ho";
    sessionPath = lib.mkIf (config.my.os == "darwin") [ "/usr/local/bin" ];
  };

  programs = {
    zsh = {
      shellAliases = {
        tf = "terraform";
      };
    };
  };
}
