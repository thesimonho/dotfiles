{ config, inputs, pkgs, pkgsUnstable, lib, ... }:
let system = pkgs.stdenv.hostPlatform.system;
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
      lazygit
      luajitPackages.luarocks_bootstrap
      neovim
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      nodejs_24
    ];

    file.".config/nvim" = {
      source = ../../nvim;
      recursive = true;
      force = true;
    };
    file.".config/wezterm" = {
      source = ../../wezterm;
      recursive = true;
      force = true;
    };
    file.".config/yazi" = {
      source = ../../yazi;
      recursive = true;
      force = true;
    };
    file.".config/lazygit" = {
      source = ../../lazygit;
      recursive = true;
      force = true;
    };
    file.".config/fzf" = {
      source = ../../fzf;
      recursive = true;
      force = true;
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
      "it.mijorus.gearlever"
      "org.gimp.GIMP"
      "org.kde.kolourpaint"
      "com.google.Chrome"
      "com.jeffser.Alpaca"
      "com.jeffser.Alpaca.Plugins.Ollama"
      "org.mozilla.firefox"
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
  xdg.configFile."starship.toml" = {
    source = ../../starship.toml;
    force = true;
  };
}

