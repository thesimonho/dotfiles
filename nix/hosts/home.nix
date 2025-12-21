{ inputs, pkgs, pkgsUnstable, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    packages = with pkgs; [  ];
  };

  services.flatpak = {
    packages = [
      "com.bitwarden.desktop"
      "com.discordapp.Discord"
      "com.dropbox.Client"
      # "io.github.berarma.Oversteer"
      # "com.calibre_ebook.calibre"
      "eu.betterbird.Betterbird"
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
    gh = { hosts = { "github.com" = { user = lib.mkForce "thesimonho"; }; }; };
    git = { settings = { user = { email = lib.mkForce "simonho.ubc@gmail.com"; }; }; };
  };
}
