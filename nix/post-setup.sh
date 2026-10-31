#!/usr/bin/env bash
# Post-HM-activation: privileged host configuration and remaining bootstrap.
#
# Arch/Fedora hosts select native app/authentication packages through the
# catalog, including KDE metapackages.
# Debian/Ubuntu still needs an APT backend; PAM wiring remains root-owned.
set -euo pipefail

is_kde() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *kde* ]] ||
    [[ "${DESKTOP_SESSION:-}" == *plasma* ]] ||
    [[ "${KDE_FULL_SESSION:-}" == "true" ]]
}

# Debian/Ubuntu package names differ from Fedora: secret-tool ships in
# libsecret-tools and the PAM module is libpam-gnome-keyring.
install_debian() {
  sudo apt-get update -y
  local pkgs=(libsecret-tools dolphin-plugins kio-gdrive)
  if is_kde; then
    pkgs+=(partitionmanager)
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
# Service to applications. v50 omits the deprecated SSH component, so it
# does not compete with the native 1Password SSH agent.
configure_pam_gnome_keyring() {
  local auth_line="auth     optional  pam_gnome_keyring.so"
  local session_line="session  optional  pam_gnome_keyring.so auto_start"
  local passwd_line="password optional  pam_gnome_keyring.so"

  local entry_files=()
  [ -f /etc/pam.d/login ] && entry_files+=(/etc/pam.d/login)
  if [ -f /etc/pam.d/sddm ]; then
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

main() {
  if [ -f /etc/debian_version ]; then
    install_debian
  elif [ ! -f /etc/arch-release ] && [ ! -f /etc/fedora-release ]; then
    echo "post-setup: unrecognized OS, skipping system package install."
    return
  fi
  if ! is_kde; then
    configure_pam_gnome_keyring
  fi
}

main "$@"
