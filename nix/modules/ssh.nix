# SSH agent, key loading, and host configuration.
# Match blocks are derived from identities in secrets/meta.nix.
# Secret key decryption is handled by secrets.nix.
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
  }) meta.identities;
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
    matchBlocks = identityMatchBlocks;
  };

  # All home.file definitions
  # - ssh-add-keys script (loads identities into the ssh-agent)
  # - ~/.ssh/config force flag (see https://github.com/nix-community/home-manager/issues/322)
  # - ~/.ssh/<key>.pub materialized from meta.nix
  home.file = lib.mkMerge [
    {
      ".ssh/config".force = true;
      ".local/bin/ssh-add-keys" = {
        executable = true;
        text =
          let
            addCommands = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: id:
                ''[ -f "${sshDir}/${id.sshKeyFile}" ] && ${pkgs.openssh}/bin/ssh-add -q "${sshDir}/${id.sshKeyFile}" </dev/null || true''
              ) meta.identities
            );
          in
          ''
            #!/usr/bin/env bash
            set -euo pipefail
            ${addCommands}
          '';
      };
    }
    (lib.mapAttrs' (name: id: {
      name = ".ssh/${id.sshKeyFile}.pub";
      value = {
        text = id.sshPublicKey + "\n";
      };
    }) (lib.filterAttrs (_: id: (id.sshPublicKey or "") != "") meta.identities))
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
