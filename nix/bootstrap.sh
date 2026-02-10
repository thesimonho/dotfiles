#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Settings
# -----------------------------
REPO_URL_DEFAULT="https://github.com/thesimonho/dotfiles"
REPO_DIR_DEFAULT="$HOME/dotfiles"
BRANCH_DEFAULT="master"
FLAKE_SUBDIR_DEFAULT="nix"

usage() {
  cat <<EOF
Usage: $(basename "$0") --host NAME [--repo URL] [--dir PATH] [--branch BRANCH] [--flake-subdir NAME]

  --host    Flake output host (required, e.g., home, work)
  --repo    Git repo URL (default: $REPO_URL_DEFAULT)
  --dir     Local checkout directory (default: $REPO_DIR_DEFAULT)
  --branch  Git branch to checkout (default: $BRANCH_DEFAULT)
  --flake-subdir  Subdirectory under the repo that contains flake.nix (default: $FLAKE_SUBDIR_DEFAULT)

Examples:
  $(basename "$0") --host home
  $(basename "$0") --host work --repo https://github.com/thesimonho/dotfiles
EOF
}

REPO_URL="$REPO_URL_DEFAULT"
REPO_DIR="$REPO_DIR_DEFAULT"
BRANCH="$BRANCH_DEFAULT"
FLAKE_SUBDIR="$FLAKE_SUBDIR_DEFAULT"
HOST="" # required, must be provided via --host

while [[ $# -gt 0 ]]; do
  case "$1" in
  --repo)
    REPO_URL="$2"
    shift 2
    ;;
  --dir)
    REPO_DIR="$2"
    shift 2
    ;;
  --host)
    HOST="$2"
    shift 2
    ;;
  --branch)
    BRANCH="$2"
    shift 2
    ;;
  --flake-subdir)
    FLAKE_SUBDIR="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown arg: $1" >&2
    usage
    exit 1
    ;;
  esac
done

if [ -z "$HOST" ]; then
  echo "Error: --host is required (e.g., --host home or --host work)" >&2
  usage
  exit 1
fi

OS="$(uname -s)"
ARCH="$(uname -m)"

echo "==> Detected OS: $OS  ARCH: $ARCH"
echo "==> Using host: $HOST"

FLAKE_DIR="${REPO_DIR}/${FLAKE_SUBDIR}"

# ------------------------------------------------------
# Helpers
# ------------------------------------------------------
detect_pkgmgr() {
  [[ "$OS" == "Linux" ]] || return 0
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo "none"
  fi
}

pkg_update() {
  [[ "$OS" == "Linux" ]] || return 0
  case "$(detect_pkgmgr)" in
  apt) sudo apt-get update -y ;;
  dnf) : ;; # typically not required
  pacman) sudo pacman -Sy ;;
  none)
    echo "No supported Linux package manager found." >&2
    ;;
  esac
}

pkg_install() {
  [[ "$OS" == "Linux" ]] || return 0
  # Usage: pkg_install pkg1 pkg2 ...
  local pm
  pm="$(detect_pkgmgr)"
  case "$pm" in
  apt)
    sudo apt-get install -y "$@"
    ;;
  dnf)
    sudo dnf install -y "$@"
    ;;
  pacman)
    sudo pacman -S --noconfirm --needed "$@"
    ;;
  none)
    echo "No supported package manager found. Please install: $*" >&2
    return 1
    ;;
  esac
}

# ------------------------------------------------------
# Ensure Git is installed
# ------------------------------------------------------
ensure_git() {
  if command -v git >/dev/null 2>&1; then
    echo "==> Git already installed."
    return 0
  fi

  echo "==> Installing git..."
  case "$OS" in
  Linux)
    pkg_install git || exit 1
    ;;
  Darwin)
    if ! xcode-select -p >/dev/null 2>&1; then
      echo "==> Installing Xcode Command Line Tools (for git)..."
      xcode-select --install || true
    fi
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
  esac
}

# ------------------------------------------------------
# Ensure Flatpak is installed and initialized system wide (Linux only)
# ------------------------------------------------------
ensure_flatpak() {
  [[ "$OS" == "Linux" ]] || return 0

  if [ -x /usr/bin/flatpak ]; then
    echo "==> System Flatpak already installed."
  else
    echo "==> Installing system Flatpak..."
    pkg_install flatpak || exit 1

    # Initialize system repo if needed
    sudo flatpak remote-add --if-not-exists --system flathub \
      https://flathub.org/repo/flathub.flatpakrepo
  fi
}

# ------------------------------------------------------
# Ensure KDE applications are installed
# ------------------------------------------------------
ensure_kde() {
  [[ "$OS" == "Linux" ]] || return 0

  # Detect KDE Plasma
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *kde* ]] ||
    [[ "${DESKTOP_SESSION:-}" == *plasma* ]] ||
    [[ "${KDE_FULL_SESSION:-}" == "true" ]]; then

    echo "KDE detected; installing KDE utilities"
    case "$(detect_pkgmgr)" in
    apt)
      pkg_install ksshaskpass partitionmanager flatpak-kcm
      ;;
    dnf)
      pkg_install ksshaskpass kde-partitionmanager
      ;;
    pacman)
      pkg_install ksshaskpass partitionmanager flatpak-kcm
      ;;
    *)
      echo "Unsupported package manager; install KDE utilities manually" >&2
      ;;
    esac
  fi
}

# ------------------------------------------------------
# Ensure Nix is installed + flakes are enabled
# ------------------------------------------------------
ensure_nix() {
  # 1. Install Nix if missing
  if command -v nix >/dev/null 2>&1; then
    echo "==> Nix already installed."
  else
    echo "==> Installing Nix (multi-user daemon)..."

    # Official installer defaults to daemon on macOS
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)

    # Defensive: fail fast if install didn’t succeed
    if ! command -v nix >/dev/null 2>&1; then
      echo "ERROR: Nix install failed or nix not on PATH" >&2
      return 1
    fi
  fi

  # 2. Enable flakes (user-scoped, safe on multi-user)
  mkdir -p "$HOME/.config/nix"
  NIXCONF="$HOME/.config/nix/nix.conf"

  if ! grep -q "^experimental-features" "$NIXCONF" 2>/dev/null; then
    echo "==> Enabling flakes in $NIXCONF"
    printf "experimental-features = nix-command flakes\n" >>"$NIXCONF"
  fi

  # 3. Source Nix environment (daemon-first, single-user fallback)
  set +u

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # Legacy single-user install (Linux or old macOS)
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  else
    echo "ERROR: Unable to locate Nix environment script" >&2
    set -u
    return 1
  fi

  set -u
}

# ------------------------------------------------------
# Clone or update repo
# ------------------------------------------------------
sync_repo() {
  if [ -d "$REPO_DIR/.git" ]; then
    echo "==> Repo exists at $REPO_DIR, pulling..."
    git -C "$REPO_DIR" fetch --all --tags
    git -C "$REPO_DIR" checkout "$BRANCH"
    git -C "$REPO_DIR" pull --rebase --autostash
  else
    echo "==> Cloning $REPO_URL to $REPO_DIR"
    git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
  fi
}

# ------------------------------------------------------
# Apply configuration
# ------------------------------------------------------
apply_host() {
  local host="$1"
  echo "==> Applying host: $host"

  case "$OS" in
  Linux)
    nix run --accept-flake-config "$FLAKE_DIR#hm" -- switch --flake "$FLAKE_DIR#$host" -b backup
    ;;
  Darwin)
    nix run nix-darwin --accept-flake-config --extra-experimental-features 'nix-command flakes' \
      -- switch --flake "$FLAKE_DIR#$host" -b backup
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 2
    ;;
  esac
}

main() {
  pkg_update || exit 1 # update package managers

  ensure_git
  ensure_kde
  ensure_nix
  ensure_flatpak
  sync_repo

  apply_host "$HOST"

  ZSH_PATH="$HOME/.nix-profile/bin/zsh"
  if ! grep -qx "$ZSH_PATH" /etc/shells; then
    echo "==> Adding nix zsh to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
  fi

  echo "==> Changing default shell to nix zsh..."
  chsh -s "$ZSH_PATH"

  if command -v mise >/dev/null 2>&1; then
    mise install || true
  fi

  echo "✅ Done. Open a new shell (or log out/in) to ensure environment is fresh."
}

main "$@"
