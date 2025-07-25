#!/bin/bash
set -euo pipefail

# Absolute paths
CONFIG_HOME="$HOME/.config"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES=$DOTFILES
USER_NAME=$(whoami)

# early zsh setup
if ! command -v zsh >/dev/null 2>&1; then
  echo "🔍 zsh not found. Attempting to install..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y zsh
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh
  else
    echo "❌ No supported package manager found. Please install zsh manually."
    exit 1
  fi
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "📦 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "$(which zsh)" ]]; then
  echo "🔧 Changing default shell to zsh..."
  ZSH_PATH=$(which zsh)

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v usermod >/dev/null 2>&1; then
      sudo usermod --shell "$ZSH_PATH" "$USER_NAME"
    else
      echo "⚠️ 'usermod' not found. Skipping shell change."
    fi
  else
    chsh -s "$ZSH_PATH"
  fi
fi

"$DOTFILES/setup/linux/zsh_plugins.sh"

# Symlink helper: $1 = source relative to repo, $2 = destination absolute path
link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "✔️ Already linked: $dest"
  else
    if [ -e "$dest" ]; then
      echo "Removing existing: $dest"
      rm -rf "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo "🔗 Linked: $dest → $src"
  fi
}

echo "Installing dotfiles..."
link_file "$DOTFILES/fzf" "$CONFIG_HOME/fzf"
link_file "$DOTFILES/lazygit" "$CONFIG_HOME/lazygit"
link_file "$DOTFILES/mcphub" "$CONFIG_HOME/mcphub"
link_file "$DOTFILES/nvim" "$CONFIG_HOME/nvim"
link_file "$DOTFILES/wezterm" "$CONFIG_HOME/wezterm"
link_file "$DOTFILES/yazi" "$CONFIG_HOME/yazi"

link_file "$DOTFILES/starship.toml" "$CONFIG_HOME/starship.toml"

link_file "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"
echo "✅ Config symlinks created."

# git
git config --global core.autocrlf input
git config --global user.name "Simon Ho"
git config --global user.email "simonho.ubc@gmail.com"
git config --global branch.sort -committerdate
git config --global column.ui auto
git config --global fetch.writeCommitGraph true
git config --global rerere.enabled true
if [[ "${GIT_SSH_REWRITE:-on}" == "on" ]]; then
  git config --global url."ssh://git@github.com/".insteadOf "https://github.com/"
fi

echo "✅ Git config created."

# ssh
for key in "$HOME/.ssh/id_"*; do
  if ! chmod 600 "$key"; then
    echo "⚠️ No keys found at $key"
  fi
done
echo "✅ SSH keys set."

# homebrew apps
"$DOTFILES/setup/linux/homebrew.sh"
