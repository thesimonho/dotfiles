{
  config,
  pkgs,
  lib,
  ...
}:
let
  isLinux = config.my.os != "darwin";
  isWSL = config.my.os == "wsl";
  hostsPath = ../hosts;
  hostEntries = builtins.readDir hostsPath;
  hostNames = map (name: lib.removeSuffix ".nix" name) (
    builtins.filter (name: lib.hasSuffix ".nix" name && hostEntries.${name} == "regular") (
      builtins.attrNames hostEntries
    )
  );
  zshWords = words: lib.concatMapStringsSep " " lib.escapeShellArg words;
in
{
  programs.zsh = {
    enable = true;
    # zsh-autocomplete owns compinit so it can populate completion results
    # asynchronously while the user types.
    enableCompletion = false;
    enableVteIntegration = true;
    history.share = false;
    autosuggestion = {
      enable = true;
      highlight = "fg=244";
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
      la = "ls -la";
      ll = "ls -l";
      lt = "ls --tree --level=2 -D";
      lg = "lazygit";
      ld = "lazydocker";
      lj = "lazyjournal";
      vim = "nvim";
      bw = lib.mkIf isLinux "flatpak run --command=bw com.bitwarden.desktop";
    };
    localVariables = {
      HYPHEN_INSENSITIVE = "true";
      ENABLE_CORRECTION = "false";
      CASE_SENSITIVE = "false";
      HIST_STAMPS = "yyyy-mm-dd";
    };
    profileExtra = "";
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

      # 110: GPG_TTY so pinentry-curses finds the controlling terminal.
      # Without it the curses prompt grabs the wrong tty and mishandles
      # input — flaky/"incorrect" passphrase entry, notably in nvim's
      # embedded terminal. updatestartuptty refreshes the running agent so
      # cache-hit prompts render on the current tty. Linux only: macOS uses
      # the pinentry-mac GUI, which needs neither.
      (lib.mkIf isLinux (
        lib.mkOrder 110 ''
          export GPG_TTY=$(tty)
          # Only nudge the agent in interactive shells — skip the
          # socket-activation cost in scripts / scp sessions.
          if [[ -o interactive ]]; then
            gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
          fi
        ''
      ))

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

      # 600: WSL — preload the SSH agent and preset the GPG signing passphrase
      # from the interactive shell. WSL has no graphical-session.target and its
      # systemd user manager has no DISPLAY, so neither the ssh-add-keys nor the
      # gpg-preset-passphrases oneshot can fire or prompt. The shell does get
      # DISPLAY via WSLg, so it runs the first-run zenity prompt (seeding
      # libsecret) and silently reloads from libsecret on later boots. A
      # per-boot marker in the tmpfs runtime dir caps each to one attempt.
      (lib.mkIf isWSL (
        lib.mkOrder 600 ''
          # Run an agent-preload command ($1) at most once per boot, keyed on a
          # marker file ($2) in the tmpfs runtime dir. Only touch the marker on
          # success, so a cancelled/failed seed retries on the next shell.
          _preload_agent_once() {
            [[ -n "$XDG_RUNTIME_DIR" ]] || return 0
            local marker="$XDG_RUNTIME_DIR/$2"
            command -v "$1" >/dev/null 2>&1 || return 0
            [[ ! -e "$marker" ]] || return 0
            # Suppress stdout only — let stderr through so a failed/cancelled
            # seed surfaces in the terminal (the sole signal on WSL).
            "$1" >/dev/null && touch "$marker"
          }
          if [[ -o interactive ]]; then
            _preload_agent_once ssh-add-keys ssh-add-keys-done
            _preload_agent_once gpg-preset-driver gpg-preset-done
          fi
          unset -f _preload_agent_once
        ''
      ))

      # 540: zsh-autocomplete must own compinit and load before compdef calls.
      (lib.mkOrder 540 ''
        source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
      '')

      # 550: completion behavior before Oh My Zsh adds its completion defaults
      (lib.mkOrder 550 ''
        typeset -A ZSH_HIGHLIGHT_REGEXP
        ZSH_HIGHLIGHT_REGEXP+=('^rm .*' fg=red,bold)

        # Wait for a deliberate pause and enough input to avoid a noisy list
        # while preserving the find-as-you-type experience.
        zstyle ':autocomplete:*' delay 0.08
        zstyle ':autocomplete:*' min-input 2
        zstyle ':autocomplete:*' timeout 0.75
        zstyle ':autocomplete:*:*' list-lines 8
      '')

      # 1000: general config
      (lib.mkOrder 1000 ''
        autoload zmv  # regex mv

        # Apply the final completion palette after Oh My Zsh has installed its
        # defaults. Use the theme's cursor accent for an unmistakable selection.
        if [[ "$IS_DAY" == "true" ]]; then
          _completion_group_color='#977865'
          _completion_selection_style='48;2;107;122;149;38;2;236;236;232;1'
        else
          _completion_group_color='#b6927b'
          _completion_selection_style='48;2;196;178;138;38;2;31;31;40;1'
        fi

        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' list-separator "  "
        zstyle ':completion:*:descriptions' format "%F{$_completion_group_color}%B%d%b%f"
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} "ma=$_completion_selection_style"
        zstyle ':completion:*:*:*:*:default' menu no no-select

        unset _completion_group_color _completion_selection_style

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

        # fzf's shell integration loads after zsh-autocomplete and claims Tab,
        # so restore the completion menu's interaction contract after both load.
        # Suggestions start unselected. Tab and Shift-Tab enter/cycle the menu,
        # Enter inserts the selected item, and Escape dismisses the menu.
        bindkey -M main '^I' menu-select
        bindkey -M main '^[[Z' reverse-menu-complete
        bindkey -M main '^[[A' up-line-or-search
        bindkey -M main '^[[B' down-line-or-select
        bindkey -M main '^[OA' up-line-or-search
        bindkey -M main '^[OB' down-line-or-select

        bindkey -M menuselect '^I' menu-complete
        bindkey -M menuselect '^[[Z' reverse-menu-complete
        bindkey -M menuselect '^M' accept-line
        bindkey -M menuselect '^[' send-break

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
        eval "$(pay-respects zsh --alias fuck --nocnf)"
      '')

      # 1600: project-specific completion enrichments after Carapace is loaded
      (lib.mkIf (config.programs.carapace.enable && config.programs.carapace.enableZshIntegration) (
        lib.mkOrder 1600 ''
          _dotfiles_host_names=(${zshWords hostNames})
          _dotfiles_describe_targets=(completions hosts skills ''${_dotfiles_host_names[@]})
          _dotfiles_doctor_modules=(completions secrets skills)

          _dotfiles_just_completion() {
            local recipe="''${words[2]}"

            if [[ $CURRENT -eq 3 ]]; then
              case "$recipe" in
                build|switch)
                  _describe -t dotfiles-hosts 'dotfiles hosts' _dotfiles_host_names
                  return
                  ;;
                describe)
                  _describe -t dotfiles-describe-targets 'dotfiles describe targets' _dotfiles_describe_targets
                  return
                  ;;
                doctor)
                  _describe -t dotfiles-doctor-modules 'dotfiles doctor modules' _dotfiles_doctor_modules
                  return
                  ;;
              esac
            fi

            _carapace_completer "$@"
          }

          compdef _dotfiles_just_completion just
        ''
      ))
    ];
    plugins = [
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
