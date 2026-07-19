{ config, ... }:

{
  my = {
    os = "arch";
    desktop = "kde";
    gpu.backend = "cuda";
    identities = [
      "personal"
      "sprung"
    ];
    secrets = [ "api-keys" ];
    browser.executable = "google-chrome-stable";
    mise.trustedPaths = [ "~/Projects" ];

    apps = {
      bundles = [
        "cli"
        "security"
        "fonts"
        "communication"
        "dev"
        "cloud"
      ];
      enabled = [
        "android-tools"
        "bitwarden"
        "ffmpeg"
        "glow"
        "onlyoffice"
        "wl-clipboard"
      ];
    };
    ai = {
      bundles = [
        "agents"
        "cli"
        "skills"
      ];
      clients = {
        claude = {
          kind = "claude";
          configDir = ".claude";
        };
        codex = {
          kind = "codex";
          configDir = ".codex";
        };
        pi = {
          kind = "pi";
          configDir = ".pi";
        };
      };
    };
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
    };
  };
}
