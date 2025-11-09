{ inputs, pkgs, pkgsUnstable, lib, ... }:

let
  nixGL = pkgs.nixgl.auto.nixGLDefault;
  wezterm = inputs.wezterm.packages.${pkgs.system}.default;
in {
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  fonts.fontconfig.enable = true;
  home = {
    sessionVariables = { EDITOR = "nvim"; };
    shell.enableZshIntegration = true;
    packages = with pkgs; [
      (pkgsUnstable.codex)
      lazygit
      luajitPackages.luarocks_bootstrap
      neovim
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      starship
      (pkgs.writeShellScriptBin "wezterm" ''
        exec ${nixGL}/bin/nixGL ${wezterm}/bin/wezterm "$@"
      '')
    ];
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
    eza = {
      enable = true;
      colors = "always";
      git = true;
      icons = "always";
    };
    fd = { enable = true; };
    fzf = { enable = true; };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
    git = {
      enable = true;
      userName = "Simon Ho";
      extraConfig = {
        branch.sort = "-committerdate";
        column.ui = "auto";
        core.autocrlf = "input";
        fetch.writeCommitGraph = true;
        rerere.enable = true;
      };
    };
    ripgrep = { enable = true; };
    tealdeer = { enable = true; };
    uv = { enable = true; };
    yazi = {
      enable = true;
      package = inputs.yazi.packages.${pkgs.system}.default.override {
        _7zz = pkgs._7zz;
      };
    };
    zoxide = { enable = true; };
    zsh = {
      enable = true;
      enableVteIntegration = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      oh-my-zsh.plugins =
        [ "colored-man-pages" "git" "jsontools" "safe-paste" ];
      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "v1.2.0";
            sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
          };
        }
        {
          name = "cd-ls";
          src = pkgs.fetchFromGitHub {
            owner = "zshzoo";
            repo = "cd-ls";
            rev = "f26c86baf50ca0e92b454753dc6f1d25228e67bf";
            sha256 = "sha256-QUnZBb0X6F42FcvNxq65zq2oB8cn1Ym4SuU8MXpIfN4=";
          };
        }
        {
          name = "dot-up";
          src = pkgs.fetchFromGitHub {
            owner = "toku-sa-n";
            repo = "zsh-dot-up";
            rev = "v0.1.3";
            sha256 = "sha256-YHs5N+qYAI2ZEjdfGgVZbii0Xuoyea8UzTzMXgFtUTA=";
          };
        }
      ];
    };
  };
}

