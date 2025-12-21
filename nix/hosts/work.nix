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
    packages = [ "com.slack.Slack" ];
    overrides = {
      "com.slack.Slack".Context = {
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
