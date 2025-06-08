#!/bin/bash
# https://brew.sh

# Ensure brew is available in PATH and env vars are set
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)" # macOS ARM
  elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # Linux
  else
    echo "❌ Homebrew not found. Please install it first." >&2
    exit 1
  fi
fi

# Map of brew package name to CLI entrypoint
declare -A packages=(
  [awscli]="aws"
  [bat]="bat"
  [carapace]="carapace"
  [devcontainer]="devcontainer"
  [direnv]="direnv"
  [eza]="eza"
  [fd]="fd"
  [fzf]="fzf"
  [gh]="gh"
  [lazygit]="lazygit"
  [luarocks]="luarocks"
  [neovim]="nvim"
  [ripgrep]="rg"
  [starship]="starship"
  [tealdeer]="tldr"
  [yazi]="yazi"
  [zoxide]="zoxide z"
)

to_install=()

for pkg in "${!packages[@]}"; do
  entrypoints="${packages[$pkg]}"
  found=0
  for entry in $entrypoints; do
    if command -v "$entry" >/dev/null 2>&1; then
      echo "$pkg: found ($entry), skipping."
      found=1
      break
    fi
  done
  if [ $found -eq 0 ]; then
    to_install+=("$pkg")
  fi
done

if [ "${#to_install[@]}" -gt 0 ]; then
  echo "Installing: ${to_install[*]}"
  brew install "${to_install[@]}"
else
  echo "All CLI tools already installed."
fi

# Fonts
fonts_list=(
  font-fira-code-nerd-font
  font-jetbrains-mono-nerd-font
)

for font in "${fonts_list[@]}"; do
  brew install --cask "$font"
done

brew autoremove
brew cleanup -s
rm -rf "$(brew --cache)"

echo "✅ Homebrew apps installed."
