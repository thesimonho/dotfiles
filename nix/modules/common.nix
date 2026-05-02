{
  config,
  lib,
  ...
}:

let
  isLinux = config.my.os != "darwin";
  dotfiles = config.my.dotfilesPath;
in
{
  imports = [ ./zsh.nix ];
  targets.genericLinux.enable = isLinux;
  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.autostart.enable = true;

  home = {
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "en_US.UTF-8";
      COLORTERM = "truecolor";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    }
    // lib.optionalAttrs (config.my.browser.executable != null) {
      CHROME_EXECUTABLE = config.my.browser.executable;
    };
    sessionPath = [
      "${config.home.homeDirectory}/.npm-global/bin"
      "${config.home.homeDirectory}/.local/bin"
    ];
    shell.enableShellIntegration = true;
  };

  programs.home-manager.enable = true;

  # Plain dotfile symlinks. Per-tool config (nvim) lives in tool modules.
  xdg.configFile = {
    "ghostty" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
      force = true;
    };
    "wezterm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
      force = true;
    };
    "lazygit" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazygit";
      force = true;
    };
    "fzf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fzf";
      force = true;
    };
    "starship.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship.toml";
      force = true;
    };
  };
}
