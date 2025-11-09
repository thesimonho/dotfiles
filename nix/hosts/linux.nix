{ config, pkgs, ... }: {
  home = {
    username = "simon";
    homeDirectory = "/home/simon";
  };

  programs = { home-manager.enable = true; };
}
