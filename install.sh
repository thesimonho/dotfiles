#!/bin/bash
set -euo pipefail

# early zsh setup
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "Changing default shell to zsh..."
  sudo usermod --shell "$(which zsh)" ${USER}
fi

./setup/linux/zsh_plugins.sh

# Absolute paths
CONFIG_HOME="$HOME/.config"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink helper: $1 = source relative to repo, $2 = destination absolute path
link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "✔ Already linked: $dest"
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
link_file "$DOTFILES/nushell" "$CONFIG_HOME/nushell"
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
git config --global url."git@github.com:".insteadOf "https://github.com/"
echo "✅ Git config created."

# ssh
for key in "$HOME/.ssh/id_"*; do
  if ! chmod 600 "$key"; then
    echo "⚠ No keys found at $key"
  fi
done
echo "✅ SSH keys set."

# homebrew apps
./setup/linux/homebrew.sh
echo "✅ Homebrew apps installed."
