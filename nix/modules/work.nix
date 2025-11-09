{ inputs, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = { packages = with pkgs; [ ]; };

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
      userEmail = "simon@sprungstudios.com";
      url = {
        "ssh://git@github.com/" = { insteadOf = "https://github.com/"; };
      };
    };
  };
}
