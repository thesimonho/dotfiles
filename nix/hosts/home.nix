{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = {
    username = lib.mkForce "simon";
    homeDirectory = lib.mkForce "/home/simon";
    sessionVariables = {
      ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
    };
    packages = [
      pkgs.android-tools
      pkgs.stripe-cli
    ];
  };
  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
    packages = [
      # "org.inkscape.Inkscape"
      # "org.gimp.GIMP"
      # "com.google.Chrome"
      "com.bitwarden.desktop"
      "org.deskflow.deskflow"
      "com.ranfdev.DistroShelf"
      "it.mijorus.gearlever"
      "com.visualstudio.code"
      "com.bitwarden.desktop"
      "com.discordapp.Discord"
      "com.dropbox.Client"
      "eu.betterbird.Betterbird"
      # "io.github.berarma.Oversteer"
      # "com.calibre_ebook.calibre"
    ];
    overrides = {
      "com.discordapp.Discord".Context = {
        filesystems = [
          "xdg-documents"
          "xdg-download"
          "xdg-pictures"
          "xdg-videos"
        ];
      };
      "eu.betterbird.Betterbird".Context = {
        filesystems = [
          "~/.gnupg:ro"
        ];
        sockets = [
          "gpg-agent"
        ];
      };
    };
  };

  ai.claudeTargetDir = lib.mkForce ".claude";
  ai.gpuBackend = lib.mkForce "cuda";
}
