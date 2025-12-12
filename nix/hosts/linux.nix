{ config, pkgs, ... }:

{
  home = {
    username = "simon";
    homeDirectory = "/home/simon";
  };

  programs.home-manager.enable = true;

  targets = { genericLinux = { enable = true; }; };

  xdg.enable = true;
  xdg.autostart.enable = true;
}
