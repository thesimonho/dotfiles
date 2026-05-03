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
  targets.genericLinux.enable = isLinux;
  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.autostart.enable = true;

  home = {
    sessionVariables = {
      LANG = "en_US.UTF-8";
      COLORTERM = "truecolor";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    }
    // lib.optionalAttrs (config.my.browser.executable != null) {
      CHROME_EXECUTABLE = config.my.browser.executable;
    };
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.npm-global/bin"
    ];
    shell.enableShellIntegration = true;
  };

  programs.home-manager.enable = true;

  # Symlinks for tools managed outside nix (installed via package managers).
  # Per-tool nix-managed configs live in their owning module/catalog entry.
  xdg.configFile = {
    "ghostty" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
      force = true;
    };
    "wezterm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
      force = true;
    };
  };
}
