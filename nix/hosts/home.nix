{ inputs, pkgs, pkgsUnstable, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    packages = with pkgs; [ flatpak ];
  };

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    remotes = [{
      name = "flathub";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }];

    packages = [
      "com.bitwarden.desktop"
      "com.discordapp.Discord"
      "com.dropbox.Client"
      "io.github.berarma.Oversteer"
      "com.calibre_ebook.calibre"
      "eu.betterbird.Betterbird"
    ];

    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    gh = { hosts = { "github.com" = { user = "thesimonho"; }; }; };
    git = { settings = { user = { email = "simonho.ubc@gmail.com"; }; }; };
  };
}
