{ config, pkgs, ... }:

{
  home = {
    username = "simon";
    homeDirectory = "/home/simon";
  };

  programs.home-manager.enable = true;

  targets = {
    genericLinux = {
      enable = true;
      nixGL = { defaultWrapper = "nvidia"; };
    };
  };

  xdg.enable = true;
  xdg.autostart.enable = true;
}
