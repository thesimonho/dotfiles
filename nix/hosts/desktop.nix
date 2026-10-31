{ config, ... }:

{
  my = {
    os = "arch";
    desktop = "kde";
    gpu.backend = "cuda";
    identities = [
      "personal"
    ];
    git.defaultIdentity = "personal";
    browser.executable = "google-chrome-stable";
    mise.trustedPaths = [ "~/Projects" ];

    apps = {
      bundles = [
        "cli"
        "desktop"
        "security"
        "fonts"
        "communication"
        "dev"
        "cloud"
        "gamedev"
      ];
      enabled = [
        "android-tools"
        "android-udev"
        "ffmpeg"
        "firefox"
        "glow"
        "google-chrome"
        "master-pdf-editor"
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
