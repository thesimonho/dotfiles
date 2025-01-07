#!/bin/bash

# git
git config --global core.autocrlf input
git config --global user.name "Simon Ho"
git config --global user.email "simonho.ubc@gmail.com"
git config --global branch.sort -committerdate
git config --global column.ui auto
git config --global fetch.writeCommitGraph true
git config --global rerere.enabled true

# symlinks
CONFIG_HOME="$HOME/.config"
DOTFILES="$HOME/Projects/dotfiles"

ln -sf "$DOTFILES/config/wezterm" "$CONFIG_HOME/wezterm"
ln -sf "$DOTFILES/config/yazi" "$CONFIG_HOME/yazi"
ln -sf "$DOTFILES/config/fzf.rc" "$CONFIG_HOME/fzf.rc"
ln -sf "$DOTFILES/config/starship.toml" "$CONFIG_HOME/starship.toml"
ln -sf "$DOTFILES/nushell" "$CONFIG_HOME"
ln -sf "$DOTFILES/lazygit" "$CONFIG_HOME"
ln -sf "$DOTFILES/nvim" "$CONFIG_HOME"