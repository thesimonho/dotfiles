{
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
    packages = [ pkgs.stripe-cli ];
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
      "org.deskflow.deskflow"
      "com.ranfdev.DistroShelf"
      "it.mijorus.gearlever"
      "com.jeffser.Alpaca"
      "com.jeffser.Alpaca.Plugins.Ollama"
      "com.visualstudio.code"
      "com.google.AndroidStudio"
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
    };
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    gh = {
      hosts = {
        "github.com" = {
          user = lib.mkForce "thesimonho";
        };
      };
    };
    git = {
      settings = {
        user = {
          email = lib.mkForce "simonho.ubc@gmail.com";
        };
      };
    };
  };

  ai.enableSymlinks = true;
  ai.gpuVendor = lib.mkForce "nvidia";
}
