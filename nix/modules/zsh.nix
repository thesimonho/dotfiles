{
  config,
  pkgs,
  lib,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    history.share = false;
    autosuggestion = {
      enable = true;
      highlight = "fg=244,underline";
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "regexp"
      ];
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
      lg = "lazygit";
      ld = "lazydocker";
      lj = "lazyjournal";
      ss = "snitch";
      netstat = "snitch";
      vim = "nvim";
      bw = lib.mkIf isLinux "flatpak run --command=bw com.bitwarden.desktop";
    };
    localVariables = {
      HYPHEN_INSENSITIVE = "true";
      ENABLE_CORRECTION = "false";
      CASE_SENSITIVE = "false";
      HIST_STAMPS = "yyyy-mm-dd";
    };
    profileExtra = ''
      export VIRTUAL_ENV_DISABLE_PROMPT=1
    '';
    initContent = lib.mkMerge [
      # 100: dawn of time
      (lib.mkOrder 100 ''
        # Ensure symlinks are italic, red, no bg (LS_COLORS ln=)
        if [[ -n "$LS_COLORS" ]]; then
          export LS_COLORS="$(
            printf '%s' "$LS_COLORS" |
              sed -E \
                -e 's/(^|:)ln=[^:]*(\:|$)/\1ln=01;36;3\2/' \
                -e 's/(^|:)or=[^:]*(\:|$)/\1or=31;01\2/'
          )"
        else
          export LS_COLORS="ln=01;36;3:or=31;01"
        fi
      '')

      # 200: load secrets
      (lib.mkOrder 200 ''
        # Load encrypted environment variables
        if [ -f ${config.age.secrets.api-keys.path} ]; then
          set -a
          source ${config.age.secrets.api-keys.path}
          set +a
        fi
      '')

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
        typeset -A ZSH_HIGHLIGHT_REGEXP
        ZSH_HIGHLIGHT_REGEXP+=('^rm .*' fg=red,bold)

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
        autoload zmv  # regex mv

        # hooks
        chpwd() {
          ls
        }

        # keybinds
        function open_file_manager() {
          zle -I        # Clear pending input or partial commands
          yazi           # Launch file manager
          zle redisplay # Redraw the prompt after Yazi exits
        }
        zle -N open_file_manager
        bindkey '^E' open_file_manager

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey '^X^E' edit-command-line

        copy-command() {
          if command -v pbcopy &> /dev/null; then
            echo -n "$BUFFER" | pbcopy
          elif command -v wl-copy &> /dev/null; then
            echo -n "$BUFFER" | wl-copy
          else
            zle -M "No clipboard tool found"
            return 1
          fi
          zle -M "Copied to clipboard"
        }
        zle -N copy-command
        bindkey '^X^C' copy-command

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
