#!/usr/bin/env bash
# Post-HM-activation: install OS-native packages that nix can't manage.
#
# KDE userland (Dolphin plugins, partitionmanager, flatpak-kcm) stays
# system-installed because KDE plugin discovery doesn't participate in
# nix profile paths.
#
# All Linux hosts get `libsecret` (for `secret-tool`) and `zenity` for
# the secret-askpass wrapper (see modules/ssh.nix). On non-KDE hosts
# we also install `gnome-keyring` to provide the Secret Service API
# that secret-tool talks to, and wire it into PAM so the keyring
# auto-unlocks at login with the user's password. KDE hosts get the
# Secret Service from KWallet, which SDDM already unlocks.
set -euo pipefail

is_kde() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *kde* ]] ||
    [[ "${DESKTOP_SESSION:-}" == *plasma* ]] ||
    [[ "${KDE_FULL_SESSION:-}" == "true" ]]
}

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null
}

install_arch() {
  local pkgs=(
    libsecret
    zenity
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

install_fedora() {
  local pkgs=(libsecret zenity)
  if ! is_wsl; then
    pkgs+=(dolphin-plugins kio-gdrive)
    if is_kde; then
      pkgs+=(kde-partitionmanager)
    fi
  fi
  if ! is_kde; then
    pkgs+=(gnome-keyring gnome-keyring-pam)
  fi
  sudo dnf install -y "${pkgs[@]}"
}

# Debian/Ubuntu — the common WSL base. Package names differ from Fedora:
# secret-tool ships in libsecret-tools, and the PAM module is
# libpam-gnome-keyring (vs gnome-keyring-pam).
install_debian() {
  sudo apt-get update -y
  local pkgs=(libsecret-tools zenity)
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
# spawns gnome-keyring-daemon so its secrets component (which serves
# the Secret Service API) is running before our ssh-add-keys oneshot
# fires. v50 no longer spawns the deprecated ssh component, so no
# conflict with our openssh ssh-agent.
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
