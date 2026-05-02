{
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

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
    username = "simon.ho";
    homeDirectory = "/Users/simon.ho";
    sessionPath = [ "/usr/local/bin" ];
  };

  programs = {
    zsh = {
      shellAliases = {
        tf = "terraform";
      };
    };
  };
}
