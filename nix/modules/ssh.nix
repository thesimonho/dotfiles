# SSH agent, key loading, and host configuration.
# Secret key decryption is handled by secrets.nix — this module consumes the decrypted keys.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
  sshDir = "${config.home.homeDirectory}/.ssh";
  meta = import ../secrets/meta.nix;
in
{
  # SSH environment variables
  xdg.configFile = {
    "environment.d/ssh.conf" = lib.mkIf isLinux {
      text = ''
        SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
        SSH_ASKPASS=/usr/bin/ksshaskpass
        SSH_ASKPASS_REQUIRE=prefer
      '';
    };
  };

  # Script to discover and add keys (id_xxx)
  home.file.".local/bin/ssh-add-keys".text = ''
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob

    keys=("${sshDir}"/id_*)
    filtered=()
    for k in "''${keys[@]}"; do
      [[ "$k" == *.pub ]] && continue
      [[ -f "$k" ]] || continue
      filtered+=("$k")
    done

    ((''${#filtered[@]})) || exit 0

    for k in "''${filtered[@]}"; do
      ${pkgs.openssh}/bin/ssh-add -q "$k" </dev/null || true
    done
  '';
  home.file.".local/bin/ssh-add-keys".executable = true;

  # Service to add keys on login
  systemd.user.services.ssh-add-keys = lib.mkIf isLinux {
    Unit = {
      Description = "Load SSH keys into agent";
      After = [ "ssh-agent.socket" ];
      Wants = [ "ssh-agent.socket" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent.socket"
        "SSH_ASKPASS=/usr/bin/ksshaskpass"
        "SSH_ASKPASS_REQUIRE=prefer"
      ];
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
        "DBUS_SESSION_BUS_ADDRESS"
      ];
      ExecStart = "${config.home.homeDirectory}/.local/bin/ssh-add-keys";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # TODO: add yubikey/rekey support https://github.com/oddlama/agenix-rekey
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        addKeysToAgent = "true";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = "${sshDir}/${meta.secrets.personal.file}";
      };
      "work-github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        addKeysToAgent = "true";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = "${sshDir}/${meta.secrets.sprung.file}";
      };
    };
  };

  # https://github.com/nix-community/home-manager/issues/322
  home.file = {
    # home-manager wrongly thinks it doesn't manage (and thus shouldn't clobber) this file due to the activation script
    ".ssh/config".force = true;
  };
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
