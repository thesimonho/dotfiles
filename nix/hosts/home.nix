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
    packages = [
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

  ai.gpuVendor = lib.mkForce "nvidia";
}
