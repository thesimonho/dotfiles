{ config, pkgs, ... }: {
  home.username = "simon";
  home.homeDirectory = "/home/simon";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [ git ];
}
