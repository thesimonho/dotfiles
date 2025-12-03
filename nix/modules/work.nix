{ inputs, pkgs, pkgsUnstable, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = { packages = with pkgs; [ flatpak ]; };

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    remotes = [{
      name = "flathub";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }];

    packages = [ "com.slack.Slack" ];

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
    awscli = {
      enable = true;
      settings = {
        "default" = {
          region = "us-west-2";
          output = "json";
        };
      };
    };
    gh = { hosts = { "github.com" = { user = "simon@sprungstudios.com"; }; }; };
    git = {
      settings = {
        user = { email = "simon@sprungstudios.com"; };
        # url = {
        #   "ssh://git@github.com/" = { insteadOf = "https://github.com/"; };
        # };
      };
    };
  };
}
