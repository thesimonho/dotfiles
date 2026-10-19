#!/usr/bin/env bash
# Post-HM-activation: privileged host configuration and remaining bootstrap.
#
# Arch/Fedora hosts select native app/authentication packages through the
# catalog, including KDE metapackages.
# WSL distro fallbacks remain here until the host selects a supported native
# platform; Debian/Ubuntu still needs an APT backend.
# PAM wiring and /etc/wsl.conf remain root-owned setup operations.
set -euo pipefail

is_kde() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *kde* ]] ||
    [[ "${DESKTOP_SESSION:-}" == *plasma* ]] ||
    [[ "${KDE_FULL_SESSION:-}" == "true" ]]
}

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null
}

install_arch_wsl() {
  local pkgs=(
    libsecret
    shelly
  )
  if is_kde; then
    pkgs+=(
      dolphin-plugins
      kio-gdrive
      extra/kde-graphics-meta
      extra/kde-system-meta
      partitionmanager
      flatpak-kcm
    )
  else
    pkgs+=(gnome-keyring)
  fi
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_arch() {
  if is_wsl; then
    install_arch_wsl
  fi
}

install_fedora() {
  # Normal Fedora hosts use native catalog declarations. WSL has no selected
  # native platform yet, so retain its authentication-package bootstrap.
  if is_wsl; then
    local pkgs=(libsecret)
    if ! is_kde; then
      pkgs+=(gnome-keyring gnome-keyring-pam)
    fi
    sudo dnf install -y "${pkgs[@]}"
  fi
}

# Debian/Ubuntu — the common WSL base. Package names differ from Fedora:
# secret-tool ships in libsecret-tools, and the PAM module is
# libpam-gnome-keyring (vs gnome-keyring-pam).
install_debian() {
  sudo apt-get update -y
  local pkgs=(libsecret-tools)
  if ! is_wsl; then
    pkgs+=(dolphin-plugins kio-gdrive)
    if is_kde; then
      pkgs+=(partitionmanager)
    fi
  fi
  if ! is_kde; then
    pkgs+=(gnome-keyring libpam-gnome-keyring)
  fi
  sudo apt-get install -y "${pkgs[@]}"
}

# Append a PAM directive to a file iff that exact line isn't already
# present. Idempotent. Args: <file> <line>.
pam_append() {
  local file="$1"
  local line="$2"
  if [ ! -f "$file" ]; then
    echo "post-setup: $file not found, skipping ($line)" >&2
    return
  fi
  if grep -qF "$line" "$file"; then
    return
  fi
  echo "$line" | sudo tee -a "$file" >/dev/null
}

# Wire pam_gnome_keyring into the auth/session/password stacks so the
# keyring auto-unlocks at login with the user's password. `auto_start`
# spawns gnome-keyring-daemon so its secrets component serves Secret
# Service to applications. SSH and GPG passphrase loading use separate
# agents. v50 omits the deprecated ssh component, so no
# conflict with our OpenSSH agent.
configure_pam_gnome_keyring() {
  local auth_line="auth     optional  pam_gnome_keyring.so"
  local session_line="session  optional  pam_gnome_keyring.so auto_start"
  local passwd_line="password optional  pam_gnome_keyring.so"

  local entry_files=()
  [ -f /etc/pam.d/login ] && entry_files+=(/etc/pam.d/login)
  if ! is_wsl && [ -f /etc/pam.d/sddm ]; then
    entry_files+=(/etc/pam.d/sddm)
  fi

  for f in "${entry_files[@]}"; do
    pam_append "$f" "$auth_line"
    pam_append "$f" "$session_line"
  done

  if [ -f /etc/pam.d/passwd ]; then
    pam_append /etc/pam.d/passwd "$passwd_line"
  fi
}

# Write /etc/wsl.conf on WSL hosts. nix (home-manager) can't manage this
# root-owned file, so it lives here. We own the file wholesale — hand-edits
# belong in this block. Takes effect only after `wsl --shutdown` from Windows.
#   systemd=true            -> required by our systemd.user services (ssh/gpg)
#   appendWindowsPath=false -> keep the huge Windows PATH out of WSL; the WSL
#                              module re-adds System32 so wslview/clip.exe live
#   automount metadata      -> real chmod/chown on /mnt/c
#   user.default            -> boot straight into this user
configure_wsl() {
  local conf=/etc/wsl.conf
  local desired
  desired="$(
    cat <<EOF
# Managed by dotfiles post-setup.sh
[boot]
systemd=true

[interop]
appendWindowsPath=false

[automount]
options=metadata

[user]
default=$(id -un)
EOF
  )"
  if [ -f "$conf" ] && [ "$(cat "$conf")" = "$desired" ]; then
    return
  fi
  echo "$desired" | sudo tee "$conf" >/dev/null
  echo "post-setup: wrote $conf — run 'wsl --shutdown' from Windows to apply."
}

main() {
  # WSL config is distro-independent, so run it before the package branch
  # (which `return`s early on an unrecognized distro like Ubuntu).
  if is_wsl; then
    configure_wsl
  fi
  if [ -f /etc/arch-release ]; then
    install_arch
  elif [ -f /etc/fedora-release ]; then
    install_fedora
  elif [ -f /etc/debian_version ]; then
    install_debian
  else
    echo "post-setup: unrecognized OS, skipping system package install."
    return
  fi
  if ! is_kde; then
    configure_pam_gnome_keyring
  fi
}

main "$@"
