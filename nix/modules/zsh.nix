{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.share = false;
    oh-my-zsh = {
      enable = true;
      plugins = [ "colored-man-pages" "git" "jsontools" "safe-paste" ];
    };
    shellAliases = {
      cat = "bat --style='header,grid'";
      eza =
        "eza --icons=always --hyperlink --group-directories-first --color=always --header";
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
        # ssh
        if [[ "$XDG_SESSION_DESKTOP" == "KDE" ]] && [[ -x /usr/bin/ksshaskpass ]]; then
          export SSH_ASKPASS_REQUIRE=prefer
          export SSH_ASKPASS="/usr/bin/ksshaskpass"
        fi

        ## Dynamically discover SSH private key filenames
        if [[ -d "$HOME/.ssh" ]]; then
          setopt extended_glob
          private_keys=($HOME/.ssh/id_*~*.pub(N))
          loaded_keys_count=$(ssh-add -l 2>/dev/null | grep -c '^')

          # Only add keys if the agent is empty or missing keys
          if (( ''${#private_keys[@]} > 0 && loaded_keys_count != ''${#private_keys[@]} )); then
            for key in "''${private_keys[@]}"; do
              ssh-add "$key" 2>/dev/null
            done
          fi
        fi

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
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=always --group-directories-first --color=always $realpath'
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' switch-group '<' '>'
      '')

      # 1000: general config
      (lib.mkOrder 1000 ''
        typeset -A ZSH_HIGHLIGHT_STYLES ZSH_HIGHLIGHT_REGEXP
        ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets regexp)
        ZSH_HIGHLIGHT_REGEXP+=('^rm .*' fg=red,bold)
        ZSH_HIGHLIGHT_STYLES[path]='fg=magenta'
        ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=green,bold'
        ZSH_HIGHLIGHT_STYLES[precommand]='fg=green,bold'
        ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=green,bold'
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=246'
      '')

      # 1500: final init
      (lib.mkOrder 1500 ''
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
