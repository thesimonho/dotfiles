{
  config,
  pkgs,
  ...
}:

let
  dotfiles = config.my.dotfilesPath;
in
{
  home.packages = [
    pkgs.neovim
    pkgs.ninja
    pkgs.lua54Packages.luarocks
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NVIM_LOG_FILE = "${config.xdg.stateHome}/nvim/nvim.log";
  };

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    force = true;
  };
}
