#!/bin/bash
set -euo pipefail

# Absolute paths
CONFIG_HOME="$HOME/.config"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  USER_NAME=$(whoami)
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
    echo "✅ Already linked: $dest"
  else
    if [ -e "$dest" ]; then
      echo "Removing existing: $dest"
      rm -rf "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo "➕ Linked: $dest → $src"
  fi
}

echo "Installing dotfiles..."
link_file "$DOTFILES/config/wezterm" "$CONFIG_HOME/wezterm"
link_file "$DOTFILES/config/fzf" "$CONFIG_HOME/fzf"
link_file "$DOTFILES/config/starship.toml" "$CONFIG_HOME/starship.toml"
link_file "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"
link_file "$DOTFILES/lazygit" "$CONFIG_HOME/lazygit"
link_file "$DOTFILES/nvim" "$CONFIG_HOME/nvim"
echo "✅ Config symlinks created."

# git
git config --global core.autocrlf input
git config --global user.name "Simon Ho"
git config --global user.email "simonho.ubc@gmail.com"
git config --global branch.sort -committerdate
git config --global column.ui auto
git config --global fetch.writeCommitGraph true
git config --global rerere.enabled true
# git config --global url."git@github.com:".insteadOf "https://github.com/"
echo "✅ Git config created."

# ssh
for key in "$HOME/.ssh/id_"*; do
  if ! chmod 600 "$key"; then
    echo "⚠ No keys found at $key"
  fi
done
echo "✅ SSH keys set."

# pass x11 display to containers for xclip/clipboard support
# https://gist.github.com/abmantis/dd372ec41eb654f2e79114ff3e2a49eb
if { [ ! -f /.dockerenv ] && ! grep -qE '(docker|lxc|containerd)' /proc/1/cgroup; }; then
  echo "Granting X11 access for local user"
  xhost +SI:localuser:$(whoami)
else
  echo "Skipping xhost (in container)"
fi

# homebrew apps
"$DOTFILES/setup/linux/homebrew.sh"
