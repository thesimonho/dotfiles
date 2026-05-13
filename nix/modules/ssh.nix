# SSH agent, key loading, and host configuration.
# Match blocks are derived from identities in secrets/meta.nix.
# Secret key decryption is handled by secrets.nix.
#
# Architecture (Linux):
#   - openssh ssh-agent runs as a user systemd service.
#   - ssh-add-keys oneshot preloads all identities at login.
#   - SSH_ASKPASS points at ~/.local/bin/secret-askpass, a thin shell
#     wrapper around `secret-tool` (libsecret CLI). First call per key
#     pops a GUI prompt (kdialog on KDE, zenity elsewhere) and stores
#     the passphrase via the Secret Service API; subsequent calls
#     retrieve silently. The backing daemon differs per host:
#       - KDE     → KWallet (PAM-unlocked at SDDM login).
#       - non-KDE → gnome-keyring's secrets component (installed +
#                   PAM-unlocked by post-setup.sh).
# gpg-agent is a separate path; see modules/gpg.nix.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = config.my.os != "darwin";
  isWSL = config.my.os == "wsl";
  sshDir = "${config.home.homeDirectory}/.ssh";
  selectedIdentities = config.my._identities;
  askpassPath = "${config.home.homeDirectory}/.local/bin/secret-askpass";

  # Derive SSH match blocks from identities
  identityMatchBlocks = lib.mapAttrs' (name: id: {
    name = id.sshHost;
    value = {
      hostname = id.sshProxyHost;
      port = id.sshPort;
      user = "git";
      addKeysToAgent = "true";
      forwardAgent = true;
      identitiesOnly = true;
      identityFile = "${sshDir}/${id.sshKeyFile}";
    };
  }) selectedIdentities;

  secretAskpassScript = ''
    #!/usr/bin/env bash
    # ssh-askpass wrapper that persists passphrases via the freedesktop
    # Secret Service API (libsecret / secret-tool). First call per key
    # prompts the user; subsequent calls retrieve silently.
    #
    # If the same parent ssh-add asks twice (i.e. the cached passphrase
    # didn't work) we clear the stale entry and fall through to a fresh
    # GUI prompt — self-healing against a wrong saved value.
    set -euo pipefail

    PROMPT="''${1:-}"

    # Extract the SSH key path from the prompt as a stable attribute
    # for libsecret. Both ssh-add and openssh include the path; trim
    # trailing punctuation (e.g. the ":" in "for key '/path/key':").
    KEY_PATH=$(printf '%s' "$PROMPT" | grep -oE '/[A-Za-z0-9_./~-]+' | head -1 || true)
    KEY_ID="''${KEY_PATH:-$PROMPT}"

    # Track invocations per ssh-add parent + key. If the marker exists
    # we're on a retry — the cached value just failed.
    state_dir="''${XDG_RUNTIME_DIR:-/tmp}/secret-askpass"
    mkdir -p "$state_dir" 2>/dev/null || true
    key_hash=$(printf '%s' "$KEY_ID" | sha1sum | cut -c1-16)
    marker="$state_dir/$PPID-$key_hash"
    # Purge stale markers (>1h) so reused PIDs don't poison us.
    find "$state_dir" -maxdepth 1 -type f -mmin +60 -delete 2>/dev/null || true

    if [ -f "$marker" ]; then
      # Retry — clear the bad cache and force a fresh prompt below.
      secret-tool clear ssh-passphrase "$KEY_ID" 2>/dev/null || true
    else
      touch "$marker"
      if command -v secret-tool >/dev/null 2>&1; then
        if PASSPHRASE=$(secret-tool lookup ssh-passphrase "$KEY_ID" 2>/dev/null) && [ -n "$PASSPHRASE" ]; then
          printf '%s\n' "$PASSPHRASE"
          exit 0
        fi
      fi
    fi

    PASSPHRASE=""
    if [ -n "''${KDE_FULL_SESSION:-}" ] && command -v kdialog >/dev/null 2>&1; then
      PASSPHRASE=$(kdialog --title "SSH passphrase" --password "$PROMPT" 2>/dev/null || true)
    elif command -v zenity >/dev/null 2>&1; then
      PASSPHRASE=$(zenity --password --title="SSH passphrase" 2>/dev/null || true)
    else
      echo "secret-askpass: no GUI prompter (kdialog/zenity) available" >&2
      exit 1
    fi

    if [ -z "$PASSPHRASE" ]; then
      exit 1
    fi

    if command -v secret-tool >/dev/null 2>&1; then
      printf '%s' "$PASSPHRASE" \
        | secret-tool store --label="SSH passphrase for $KEY_ID" ssh-passphrase "$KEY_ID" 2>/dev/null \
        || true
    fi

    printf '%s\n' "$PASSPHRASE"
  '';
in
{
  xdg.configFile = {
    "environment.d/ssh.conf" = lib.mkIf isLinux {
      text = ''
        SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
        SSH_ASKPASS=${askpassPath}
        SSH_ASKPASS_REQUIRE=prefer
      '';
    };
  };

  # WSL only: environment.d feeds `systemd --user`, and on a real DE
  # plasma-startup re-exports those vars into the session so every shell
  # inherits them. WSL has no such propagation step — terminals aren't
  # children of systemd-user — so SSH_AUTH_SOCK/SSH_ASKPASS never reach
  # the shell and ssh falls back to terminal prompts. Mirror the same
  # values via home.sessionVariables → hm-session-vars.sh, which every
  # shell sources on startup. XDG_RUNTIME_DIR is set by pam_systemd
  # before this runs, so the path resolves correctly.
  home.sessionVariables = lib.mkIf isWSL {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    SSH_ASKPASS = askpassPath;
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # openssh ssh-agent as a user systemd service. Not socket-activated:
  # openssh's ssh-agent doesn't speak the systemd LISTEN_FDS protocol,
  # so a socket unit + `-a <path>` collide on bind. The service binds
  # the socket itself; ExecStartPre clears any stale file.
  systemd.user.services.ssh-agent = lib.mkIf isLinux {
    Unit.Description = "OpenSSH agent";
    Service = {
      Type = "simple";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
      ExecStartPre = "-${pkgs.coreutils}/bin/rm -f %t/ssh-agent.socket";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent.socket";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Preload identity keys at login. The askpass wrapper handles
  # lookup/store via libsecret; first invocation per key shows a GUI
  # prompt, subsequent runs are silent.
  systemd.user.services.ssh-add-keys = lib.mkIf isLinux {
    Unit = {
      Description = "Load SSH keys into agent";
      # graphical-session.target ensures the DE has imported
      # DBUS_SESSION_BUS_ADDRESS/DISPLAY/WAYLAND_DISPLAY into the user
      # systemd env. Without it, our askpass can't reach the Secret
      # Service daemon and silently returns empty.
      After = [
        "ssh-agent.service"
        "graphical-session.target"
      ];
      Wants = [ "ssh-agent.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent.socket"
        "SSH_ASKPASS=${askpassPath}"
        "SSH_ASKPASS_REQUIRE=prefer"
      ];
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
        "DBUS_SESSION_BUS_ADDRESS"
        "KDE_FULL_SESSION"
        "XDG_CURRENT_DESKTOP"
      ];
      ExecStart = "${config.home.homeDirectory}/.local/bin/ssh-add-keys";
      # Cap the unit so a hidden/hung askpass dialog doesn't stall
      # subsequent `home-manager switch` invocations.
      TimeoutStartSec = "60";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # TODO: add yubikey/rekey support https://github.com/oddlama/agenix-rekey
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = identityMatchBlocks;
  };

  # All home.file definitions
  # - ssh-add-keys script (loads identities into the ssh-agent)
  # - secret-askpass wrapper (libsecret-backed SSH_ASKPASS)
  # - ~/.ssh/config force flag (see https://github.com/nix-community/home-manager/issues/322)
  # - ~/.ssh/<key>.pub materialized from meta.nix
  home.file = lib.mkMerge [
    {
      ".ssh/config".force = true;
    }
    (lib.mkIf isLinux {
      ".local/bin/ssh-add-keys" = {
        executable = true;
        text =
          let
            addCommands = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: id: ''add_key "${sshDir}/${id.sshKeyFile}"'') selectedIdentities
            );
          in
          ''
            #!/usr/bin/env bash
            set -euo pipefail

            # Show a passive desktop notification — used only to surface
            # ssh-add failures so they don't fail silently.
            notify() {
              if [ -n "''${KDE_FULL_SESSION:-}" ] && command -v kdialog >/dev/null 2>&1; then
                kdialog --title "SSH" --passivepopup "$1" 8 >/dev/null 2>&1 || true
              elif command -v notify-send >/dev/null 2>&1; then
                notify-send -u critical "SSH" "$1" >/dev/null 2>&1 || true
              fi
              # Always echo to stderr too — that's the only signal on
              # headless / no-notification-daemon hosts (e.g. WSL).
              # systemd captures it into the unit's journal.
              echo "ssh-add-keys: $1" >&2
            }

            add_key() {
              local key="$1"
              [ -f "$key" ] || return 0
              if ! ${pkgs.openssh}/bin/ssh-add -q "$key" </dev/null; then
                notify "Failed to load $key — run \`ssh-keys clear-one $key\` and retry."
              fi
            }

            ${addCommands}
          '';
      };
      ".local/bin/ssh-keys" = {
        executable = true;
        text =
          let
            keyPaths = lib.concatStringsSep " " (
              lib.mapAttrsToList (_: id: ''"${sshDir}/${id.sshKeyFile}"'') selectedIdentities
            );
          in
          ''
            #!/usr/bin/env bash
            # Manage SSH passphrases stored in libsecret/Secret Service.
            # Knows about the identity key files declared in meta.nix.
            set -euo pipefail

            keys=( ${keyPaths} )
            cmd="''${1:-list}"

            case "$cmd" in
              list)
                for k in "''${keys[@]}"; do
                  if secret-tool lookup ssh-passphrase "$k" >/dev/null 2>&1; then
                    printf '  stored: %s\n' "$k"
                  else
                    printf '  empty:  %s\n' "$k"
                  fi
                done
                ;;
              clear)
                for k in "''${keys[@]}"; do
                  if secret-tool clear ssh-passphrase "$k" 2>/dev/null; then
                    printf '  cleared: %s\n' "$k"
                  fi
                done
                ;;
              clear-one)
                : "''${2:?usage: ssh-keys clear-one <key-path>}"
                secret-tool clear ssh-passphrase "$2"
                ;;
              show)
                # Print stored passphrases in plaintext. Limit to a
                # single key when one is passed.
                targets=( "''${keys[@]}" )
                [ -n "''${2:-}" ] && targets=( "$2" )
                for k in "''${targets[@]}"; do
                  if val=$(secret-tool lookup ssh-passphrase "$k" 2>/dev/null) && [ -n "$val" ]; then
                    printf '%s: %s\n' "$k" "$val"
                  else
                    printf '%s: (empty)\n' "$k"
                  fi
                done
                ;;
              *)
                echo "usage: ssh-keys [list|show [path]|clear|clear-one <path>]" >&2
                exit 1
                ;;
            esac
          '';
      };
      ".local/bin/secret-askpass" = {
        executable = true;
        text = secretAskpassScript;
      };
    })
    (lib.mapAttrs' (name: id: {
      name = ".ssh/${id.sshKeyFile}.pub";
      value = {
        text = id.sshPublicKey + "\n";
      };
    }) (lib.filterAttrs (_: id: (id.sshPublicKey or "") != "") selectedIdentities))
  ];

  home.activation = {
    fixSshPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run install -d -m 0700 "$HOME/.ssh"
      if [ -L "$HOME/.ssh/config" ]; then
        src="$(readlink -f "$HOME/.ssh/config")"
        run rm -f "$HOME/.ssh/config"
        run install -m 0600 "$src" "$HOME/.ssh/config"
      fi
    '';
  };
}
