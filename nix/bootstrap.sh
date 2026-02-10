#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Defaults
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
HOST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_URL="$2"; shift 2 ;;
    --dir) REPO_DIR="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --flake-subdir) FLAKE_SUBDIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$HOST" ]]; then
  echo "Error: --host is required (e.g., --host home or --host work)" >&2
  usage
  exit 1
fi

OS="$(uname -s)"
ARCH="$(uname -m)"
echo "==> Detected OS: $OS  ARCH: $ARCH"
echo "==> Using host: $HOST"

FLAKE_DIR="${REPO_DIR}/${FLAKE_SUBDIR}"

# -----------------------------
# Helpers
# -----------------------------
nix_cmd() {
  # Always pass experimental features so fresh installs work even before config is set.
  nix --extra-experimental-features "nix-command flakes" "$@"
}

detect_pkgmgr() {
  [[ "$OS" == "Linux" ]] || { echo "none"; return 0; }
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
    none) echo "No supported Linux package manager found." >&2 ;;
  esac
}

pkg_install() {
  [[ "$OS" == "Linux" ]] || return 0
  local pm
  pm="$(detect_pkgmgr)"
  case "$pm" in
    apt) sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm --needed "$@" ;;
    none)
      echo "No supported package manager found. Please install: $*" >&2
      return 1
      ;;
  esac
}

restart_nix_daemon() {
  case "$OS" in
    Darwin)
      echo "==> Restarting nix-daemon (macOS)"
      sudo launchctl kickstart -k system/org.nixos.nix-daemon
      ;;
    Linux)
      echo "==> Restarting nix-daemon (Linux)"
      if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl restart nix-daemon.service 2>/dev/null || true
        sudo systemctl restart nix-daemon 2>/dev/null || true
      fi
      ;;
  esac
}

# -----------------------------
# Git
# -----------------------------
ensure_git() {
  if command -v git >/dev/null 2>&1; then
    echo "==> Git already installed."
    return 0
  fi

  echo "==> Installing git..."
  case "$OS" in
    Linux)
      pkg_install git || return 1
      ;;
    Darwin)
      if ! xcode-select -p >/dev/null 2>&1; then
        echo "==> Installing Xcode Command Line Tools (for git)..."
        xcode-select --install || true
      fi
      ;;
    *)
      echo "Unsupported OS: $OS" >&2
      return 1
      ;;
  esac

  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git still not available. Finish installing prerequisites then rerun." >&2
    return 1
  fi
}

# -----------------------------
# Flatpak (Linux only)
# -----------------------------
ensure_flatpak() {
  [[ "$OS" == "Linux" ]] || return 0

  if command -v flatpak >/dev/null 2>&1; then
    echo "==> System Flatpak already installed."
  else
    echo "==> Installing system Flatpak..."
    pkg_install flatpak || return 1
  fi

  # Ensure flathub system remote exists
  sudo flatpak remote-add --if-not-exists --system flathub \
    https://flathub.org/repo/flathub.flatpakrepo
}

# -----------------------------
# KDE utilities (Linux only)
# -----------------------------
ensure_kde() {
  [[ "$OS" == "Linux" ]] || return 0

  # Detect KDE Plasma
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *kde* ]] ||
     [[ "${DESKTOP_SESSION:-}" == *plasma* ]] ||
     [[ "${KDE_FULL_SESSION:-}" == "true" ]]; then

    echo "==> KDE detected; installing KDE utilities"
    case "$(detect_pkgmgr)" in
      apt) pkg_install ksshaskpass partitionmanager flatpak-kcm ;;
      dnf) pkg_install ksshaskpass kde-partitionmanager ;;
      pacman) pkg_install ksshaskpass partitionmanager flatpak-kcm ;;
      *)
        echo "Unsupported package manager; install KDE utilities manually" >&2
        ;;
    esac
  fi
}

# -----------------------------
# Nix (multi-user/daemon)
# -----------------------------
ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    echo "==> Nix already installed."
  else
    echo "==> Installing Nix (daemon/multi-user)..."
    case "$OS" in
      Darwin)
        # Official installer defaults to daemon on macOS.
        sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
        ;;
      Linux)
        # Force daemon mode on Linux too.
        sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
        ;;
      *)
        echo "Unsupported OS: $OS" >&2
        return 1
        ;;
    esac
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo "ERROR: nix not on PATH after install. Open a new shell and rerun." >&2
    return 1
  fi

  # Enable flakes in daemon config (authoritative for multi-user)
  local conf="/etc/nix/nix.conf"
  if ! grep -Eq '^\s*experimental-features\s*=.*\bnix-command\b' "$conf" 2>/dev/null; then
    echo "==> Enabling flakes in $conf"
    echo "experimental-features = nix-command flakes" | sudo tee -a "$conf" >/dev/null
    restart_nix_daemon || true
  fi

  # Optional: user-scoped config too (nice-to-have)
  mkdir -p "$HOME/.config/nix"
  local user_conf="$HOME/.config/nix/nix.conf"
  if ! grep -Eq '^\s*experimental-features\s*=' "$user_conf" 2>/dev/null; then
    echo "==> Enabling flakes in $user_conf"
    echo "experimental-features = nix-command flakes" >>"$user_conf"
  fi
}

# -----------------------------
# Repo sync
# -----------------------------
sync_repo() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    echo "==> Repo exists at $REPO_DIR, pulling..."
    git -C "$REPO_DIR" fetch --all --tags
    git -C "$REPO_DIR" checkout "$BRANCH"
    git -C "$REPO_DIR" pull --rebase --autostash
  else
    echo "==> Cloning $REPO_URL to $REPO_DIR"
    git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
  fi
}

# -----------------------------
# Apply host (Home Manager on both OSes)
# -----------------------------
apply_host() {
  local host="$1"
  echo "==> Applying host: $host"
  echo "==> Flake dir: $FLAKE_DIR"

  nix_cmd run --accept-flake-config "$FLAKE_DIR#hm" -- \
    switch --flake "$FLAKE_DIR#$host"
}

# -----------------------------
# Optional: set default shell to Nix-provided zsh (if present)
# -----------------------------
ensure_nix_zsh_shell() {
  local zsh_path="$HOME/.nix-profile/bin/zsh"

  if [[ ! -x "$zsh_path" ]]; then
    echo "==> Nix zsh not found at $zsh_path (maybe HM doesn't install zsh yet). Skipping chsh."
    return 0
  fi

  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    echo "==> Adding nix zsh to /etc/shells..."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  echo "==> Changing default shell to nix zsh..."
  chsh -s "$zsh_path" || true
}

maybe_mise_install() {
  if command -v mise >/dev/null 2>&1; then
    echo "==> Running mise install..."
    mise install || true
  fi
}

main() {
  pkg_update || true

  ensure_git
  ensure_kde
  ensure_nix
  ensure_flatpak
  sync_repo

  apply_host "$HOST"
  ensure_nix_zsh_shell
  maybe_mise_install

  echo "✅ Done. Open a new shell (or log out/in) to ensure environment is fresh."
}

main "$@"
