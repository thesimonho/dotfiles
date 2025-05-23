#!/bin/bash
# https://brew.sh

# Map of brew package name to CLI entrypoint
declare -A packages=(
  [bat]="bat"
  [carapace]="carapace"
  [coreutils]="gls"
  [direnv]="direnv"
  [fd]="fd"
  [fzf]="fzf"
  [gh]="gh"
  [lazygit]="lazygit"
  [luarocks]="luarocks"
  [neovim]="nvim"
  [ripgrep]="rg"
  [starship]="starship"
  [tealdeer]="tldr"
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

echo "✅ Homebrew apps installed."
