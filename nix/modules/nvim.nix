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

  # Mason installs LSP/formatters/etc. under this dir; ensure they're on PATH.
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/nvim/mason/bin"
  ];

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    force = true;
  };
}
