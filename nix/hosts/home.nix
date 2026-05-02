{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

{
  my = {
    os = "arch";
    desktop = "kde";
    gpu = {
      backend = "cuda";
      cuda.capabilities = [ "8.6" ];
    };
    identities = [
      "personal"
      "sprung"
    ];
    secrets = [ "api-keys" ];
    browser.executable = "google-chrome-stable";
    apps = {
      bundles = [
        "baseline"
        "security-tools"
        "fonts"
        "communication"
        "desktop"
        "mobile-dev"
        "creative"
        "cloud"
        "linux-utils"
      ];
      enabled = [ ];
    };
    ai = {
      bundles = [
        "cli-agents"
        "tooling"
        "local-models"
      ];
      claude.targetDir = ".claude";
    };
  };

  home = {
    username = lib.mkForce "simon";
    homeDirectory = lib.mkForce "/home/simon";
    sessionVariables = {
      ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
    };
  };
}
