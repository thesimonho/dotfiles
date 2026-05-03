#!/usr/bin/env bash
# Post-HM-activation: install OS-native packages that nix can't manage.
# KDE userland (Dolphin plugins, ksshaskpass, partitionmanager, flatpak-kcm)
# stays system-installed because KDE plugin discovery doesn't participate
# in nix profile paths.
set -euo pipefail

is_kde() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *kde* ]] ||
    [[ "${DESKTOP_SESSION:-}" == *plasma* ]] ||
    [[ "${KDE_FULL_SESSION:-}" == "true" ]]
}

install_arch() {
  local pkgs=(
    dolphin-plugins
    kio-gdrive
    extra/kde-graphics-meta
    extra/kde-system-meta
    shelly
  )
  if is_kde; then
    pkgs+=(ksshaskpass partitionmanager flatpak-kcm)
  fi
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_fedora() {
  local pkgs=(
    dolphin-plugins
    kio-gdrive
  )
  if is_kde; then
    pkgs+=(ksshaskpass kde-partitionmanager)
  fi
  sudo dnf install -y "${pkgs[@]}"
}

main() {
  if [ -f /etc/arch-release ]; then
    install_arch
  elif [ -f /etc/fedora-release ]; then
    install_fedora
  else
    echo "post-setup: unrecognized OS, skipping system package install."
  fi
}

main "$@"
