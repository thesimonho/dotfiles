{ config, inputs, pkgs, pkgsUnstable, lib, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in {
  imports = [ ./zsh.nix ];

  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  fonts.fontconfig.enable = true;
  home = {
    sessionVariables = {
      EDITOR = "nvim";
      LANG = "en_US.UTF-8";
      COLORTERM = "truecolor";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    };
    sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];
    shell.enableZshIntegration = true;
    packages = with pkgs; [
      (pkgsUnstable.codex)
      docker
      eza
      flatpak
      lazydocker
      lazygit
      lazyjournal
      luajitPackages.luarocks_bootstrap
      neovim
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      pay-respects
      inputs.ghostty.packages.${system}.default

      go_1_24
      rustup
      nodejs_24
      python311
    ];

    # applications
    file.".local/share/applications/ghostty.desktop" = {
      executable = true;
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Ghostty
        Exec=ghostty
        Icon=com.mitchellh.ghostty
        Terminal=false
        Categories=System;TerminalEmulator;
      '';
    };
  };

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    remotes = [{
      name = "flathub";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }];

    packages = [
      "org.deskflow.deskflow"
      "com.ranfdev.DistroShelf"
      "com.github.tchx84.Flatseal"
      "it.mijorus.gearlever"
      "org.gimp.GIMP"
      "com.google.Chrome"
      "com.jeffser.Alpaca"
      "com.jeffser.Alpaca.Plugins.Ollama"
      "org.mozilla.firefox"
      "io.podman_desktop.PodmanDesktop"
      "com.visualstudio.code"
    ];

    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    bat = { enable = true; };
    carapace = { enable = true; };
    direnv = {
      enable = true;
      silent = true;
    };
    fd = { enable = true; };
    fzf = { enable = true; };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
    git = {
      enable = true;
      lfs = { enable = true; };
      maintenance = { enable = true; };
      settings = {
        user = { name = "Simon Ho"; };
        core = { autocrlf = "input"; };
        rerere = { enabled = true; };
        column = { ui = "auto"; };
        branch = { sort = "-committerdate"; };
        fetch = { writeCommitGraph = true; };
      };
    };
    ripgrep = { enable = true; };
    starship = { enable = true; };
    tealdeer = { enable = true; };
    yazi = {
      enable = true;
      package =
        inputs.yazi.packages.${system}.default.override { _7zz = pkgs._7zz; };
    };
    zoxide = { enable = true; };
  };

  # symlinks
  home.file.".codex" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/codex";
    force = true;
  };

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    force = true;
  };
  xdg.configFile."wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
    force = true;
  };
  xdg.configFile."yazi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/yazi";
    force = true;
  };
  xdg.configFile."lazygit" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazygit";
    force = true;
  };
  xdg.configFile."mcphub" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/mcphub";
    force = true;
  };
  xdg.configFile."fzf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fzf";
    force = true;
  };
  xdg.configFile."starship.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship.toml";
    force = true;
  };

}

