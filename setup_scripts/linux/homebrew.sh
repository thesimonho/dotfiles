#!/bin/bash
# https://brew.sh

brew install bat
brew install carapace
brew install chafa
brew install distrobox
brew install fd
brew install ffmpeg
brew install gh
brew install lazygit
brew install luarocks
brew install neovim
brew install node
brew install nushell
brew install pandoc
brew install ripgrep
brew install sqlite
brew install starship
brew install yazi sevenzip jq poppler imagemagick
brew install zoxide

# Fonts
fonts_list=(
  font-fira-code-nerd-font
  font-monaspace-nerd-font
  font-monofur-nerd-font
  font-departure-mono-nerd-font
  font-jetbrains-mono-nerd-font
)

for font in "${fonts_list[@]}"; do
  brew install --cask "$font"
done
