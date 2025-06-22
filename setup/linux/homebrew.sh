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
  [uv]="uv"
  [yazi]="yazi"
  [zoxide]="zoxide z"
)

to_install=()

for pkg in "${!packages[@]}"; do
  entrypoints="${packages[$pkg]}"
  found=0
  for entry in $entrypoints; do
    if command -v "$entry" >/dev/null 2>&1; then
      echo "✔️ $pkg: found ($entry), skipping."
      found=1
      break
    fi
  done
  if [ $found -eq 0 ]; then
    to_install+=("$pkg")
  fi
done

if [ "${#to_install[@]}" -gt 0 ]; then
  echo "📦 Installing: ${to_install[*]}"
  brew install "${to_install[@]}"
else
  echo "✅ All CLI tools installed."
fi

# Yazi plugins
if command -v ya >/dev/null 2>&1; then
  if [ -f "$DOTFILES/yazi/package.toml" ]; then
    if find "$DOTFILES/yazi" -mindepth 2 -type d | read; then
      echo "⬆️ Updating yazi packages..."
      ya pkg upgrade
    else
      echo "📦 Installing yazi packages from lock file..."
      ya pkg install
    fi
  else
    yazi_plugins=(
      "yazi-rs/plugins:git"
      "yazi-rs/plugins:smart-paste"
      "yazi-rs/plugins:full-border"
      "yazi-rs/plugins:chmod"
    )

    for plugin in "${yazi_plugins[@]}"; do
      ya pkg add "$plugin"
    done
  fi
fi

# Fonts
fonts_list=(
  font-fira-code-nerd-font
  font-jetbrains-mono-nerd-font
)

for font in "${fonts_list[@]}"; do
  if brew list --cask "$font" &>/dev/null; then
    echo "✔️ $font is already installed"
  else
    echo "📦 Installing $font..."
    brew install --cask "$font"
  fi
done

# Cleanup
echo "🧹 Cleaning up..."
brew autoremove
brew cleanup -s
rm -rf "$(brew --cache)"

echo "✅ Homebrew apps installed."
