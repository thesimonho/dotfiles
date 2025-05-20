#!/bin/bash
# https://brew.sh

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Map of brew package name to CLI entrypoint
declare -A packages=(
  [bat]="bat"
  [carapace]="carapace"
  [chafa]="chafa"
  [distrobox]="distrobox"
  [direnv]="direnv"
  [fd]="fd"
  [ffmpeg]="ffmpeg"
  [fzf]="fzf"
  [gh]="gh"
  [lazygit]="lazygit"
  [luarocks]="luarocks"
  [neovim]="nvim"
  [node]="node"
  [nushell]="nu"
  [pandoc]="pandoc"
  [ripgrep]="rg"
  [sqlite]="sqlite3"
  [starship]="starship"
  [tealdeer]="tldr"
  [yazi]="yazi"
  [sevenzip]="7zz"
  [jq]="jq"
  [poppler]="pdftotext"
  [imagemagick]="magick"
  ['uutils-coreutils']="uutils"
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
  font-monaspace-nerd-font
  font-departure-mono-nerd-font
  font-jetbrains-mono-nerd-font
)

for font in "${fonts_list[@]}"; do
  brew install --cask "$font"
done
