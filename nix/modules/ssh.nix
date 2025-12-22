{
  config,
  pkgs,
  lib,
  ...
}:

let
  sshDir = "${config.home.homeDirectory}/.ssh";
  meta = import ../secrets/meta.nix;

  mkSecret = name: item: {
    name = "${name}";
    value = {
      file = builtins.toPath "${../secrets}/${item.file}.age";
      path = "${sshDir}/${item.file}";
      mode = "600";
      symlink = false;
    };
  };
in
{
  home = {
    packages = with pkgs; [ age ];
  };

  # set ssh env variables
  xdg.configFile."environment.d/ssh.conf".text = ''
    SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
    SSH_ASKPASS=/usr/bin/ksshaskpass
    SSH_ASKPASS_REQUIRE=prefer
  '';

  # script to discover and add keys (id_xxx)
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

  # service to add keys on login
  systemd.user.services.ssh-add-keys = {
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

  # TODO: add yubikey support https://github.com/oddlama/agenix-rekey
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
        identityFile = "${sshDir}/${meta.sprung.file}";
      };
      "personal-github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        addKeysToAgent = "true";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = "${sshDir}/${meta.personal.file}";
      };
    };
  };
  age = {
    identityPaths = [ "${sshDir}/ssh_identity" ];
    secrets = lib.mapAttrs' mkSecret meta;
  };
}
