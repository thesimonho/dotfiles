{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    history.share = false;
    autosuggestion = {
      enable = true;
      highlight = ''
        fg=246
      '';
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "pattern"
      ];
      patterns = {
        "rm *" = "fg=red,bold";
        "sudo rm *" = "bg=red,fg=white";
      };
      styles = {
        path = "fg=magenta";
        suffix-alias = "fg=green,bold";
        precommand = "fg=green,bold";
        autodirectory = "fg=green,bold";
      };
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "colored-man-pages"
        "git"
        "jsontools"
        "safe-paste"
        "mise"
      ];
    };
    shellAliases = {
      cat = "bat --style='header,grid'";
      ls = "eza";
      la = "eza -la";
      ll = "eza -l";
      lt = "eza --tree";
      tf = "terraform";
      lg = "lazygit";
      ld = "lazydocker";
      vim = "nvim";
    };
    localVariables = {
      HYPHEN_INSENSITIVE = "true";
      ENABLE_CORRECTION = "false";
      CASE_SENSITIVE = "false";
      HIST_STAMPS = "yyyy-mm-dd";
    };
    initContent = lib.mkMerge [
      # 500: early init
      (lib.mkOrder 500 ''
        # Determine if it's day or night for theming purposes
        hour=$(date +%H)
        if (( 7 <= hour && hour < 19 )); then
          export IS_DAY=true
        else
          export IS_DAY=false
        fi

        if [[ "$IS_DAY" == "true" ]]; then
          export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/kanagawa-paper-canvas.rc"
        else
          export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/kanagawa-paper-ink.rc"
        fi
      '')

      # 550: before compinit — completion styles & fzf-tab zstyles
      (lib.mkOrder 550 ''
        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu no

        # fzf-tab styles
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 $realpath'
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' switch-group '<' '>'
      '')

      # 1000: general config
      (lib.mkOrder 1000 ''
        # keybinds
        function open_file_manager() {
          zle -I        # Clear pending input or partial commands
          yazi           # Launch file manager
          zle redisplay # Redraw the prompt after Yazi exits
        }

        zle -N open_file_manager
        bindkey '^E' open_file_manager
        bindkey '^[l' autosuggest-accept # alt+L to accept autosuggestion
        bindkey '^H' backward-kill-word # ctrl backspace
        bindkey '^[[3;5~' kill-word # ctrl delete
      '')

      # 1500: final init
      (lib.mkOrder 1500 ''
        eval "$(pay-respects zsh --alias fuck)"
      '')
    ];
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
}
