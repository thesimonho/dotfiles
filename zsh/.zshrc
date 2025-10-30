# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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
  if (( ${#private_keys[@]} > 0 && loaded_keys_count != ${#private_keys[@]})); then
    for key in "${private_keys[@]}"; do
      ssh-add "$key" 2>/dev/null
    done
  fi
fi

hour=$(date +%H)
if (( 7 <= hour && hour < 19 )); then
  export IS_DAY=true
else
  export IS_DAY=false
  export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/kanagawa-paper-ink.rc"
fi

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false" 

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(cd-ls colored-man-pages fzf-tab git jsontools safe-paste zsh-autosuggestions zsh-dot-up zsh-syntax-highlighting)

typeset -A ZSH_HIGHLIGHT_STYLES ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets regexp)
ZSH_HIGHLIGHT_REGEXP+=('^rm .*' fg=red,bold)
ZSH_HIGHLIGHT_STYLES[path]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=green,bold'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=246'

zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with ls when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=always --group-directories-first --color=always $realpath'
# To make fzf-tab follow FZF_DEFAULT_OPTS.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

export COLORTERM=truecolor

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
maybe_alias() {
  if command -v "$1" >/dev/null 2>&1; then
    alias "$2"
  fi
}

maybe_alias bat "cat=bat --style='header,grid'"
maybe_alias eza "ls=eza --icons=always --hyperlink --group-directories-first --color=always --header"
alias la='ls -la'
alias ll='ls -l'
alias tf='terraform'
alias lg='lazygit'
alias vim='nvim'

# keybinds
function open_file_manager() {
  zle -I        # Clear pending input or partial commands
  spf           # Launch file manager
  zle redisplay # Redraw the prompt after Yazi exits
}

zle -N open_file_manager
bindkey '^E' open_file_manager
bindkey '^[l' autosuggest-accept # alt+L to accept autosuggestion. do this at the end
bindkey '^H' backward-kill-word # ctrl backspace
bindkey '^[[3;5~' kill-word # ctrl delete

if [[ "$IS_DAY" == "true" ]]; then
  export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/kanagawa-paper-canvas.rc"
else
  export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/kanagawa-paper-ink.rc"
fi

# add homebrew path depending on osx or linux
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="brew"
else
  if [ -f /opt/homebrew/bin/brew ]; then
    BREW_PREFIX="/opt/homebrew/bin/brew"  # macOS ARM
  elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew/bin/brew"  # Linux
  else
    echo "❌ Homebrew not found. Please install it first." >&2
    exit 1
  fi
  eval "$($BREW_PREFIX shellenv)"
fi

# if [[ -z "$ZELLIJ" ]]; then
#     if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
#         zellij attach -c
#     else
#       if [[ "$IS_DAY" == "true" ]]; then
#         zellij options --theme kanagawa-paper-canvas
#       else
#         zellij options --theme kanagawa-paper-ink
#       fi
#     fi
#
#     if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
#         exit
#     fi
# fi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
source <(carapace _carapace)
