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
      "io.github.berarma.Oversteer"
      "com.calibre_ebook.calibre"
      "eu.betterbird.Betterbird"
    ];
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    gh = { hosts = { "github.com" = { user = "thesimonho"; }; }; };
    git = { settings = { user = { email = "simonho.ubc@gmail.com"; }; }; };
  };
}
