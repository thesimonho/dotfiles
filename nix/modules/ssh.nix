# SSH agent, key loading, and host configuration.
# Match blocks are derived from identities in secrets/meta.nix.
# KDE loads encrypted backups directly into the agent through session-secrets.
# Other platforms retain file deployment from secrets.nix.
#
# Linux KDE uses ksshaskpass and KWallet directly. WSL retains the agent and
# encrypted identities, but prompts in the terminal and does not preload keys.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = config.my.os != "darwin";
  isKde = config.my.desktop == "kde";
  nativeKde = isLinux && config.my.os != "wsl" && isKde;
  sshDir = "${config.home.homeDirectory}/.ssh";
  selectedIdentities = config.my._identities;

  identitySettings = lib.mapAttrs' (name: id: {
    name = id.sshHost;
    value = {
      HostName = id.sshProxyHost;
      Port = id.sshPort;
      User = "git";
      AddKeysToAgent = "true";
      ForwardAgent = true;
      IdentitiesOnly = true;
      IdentityFile = "${sshDir}/${id.sshKeyFile}${lib.optionalString nativeKde ".pub"}";
    };
  }) selectedIdentities;
in
{
  xdg.configFile = {
    "environment.d/ssh.conf" = lib.mkIf isLinux {
      text = ''
        SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
      ''
      + lib.optionalString nativeKde ''
        SSH_ASKPASS=/usr/bin/ksshaskpass
        SSH_ASKPASS_REQUIRE=prefer
      '';
    };
  };

  # WSL shells do not inherit systemd's environment. Keep the agent socket
  # visible there; terminal SSH prompts load identities into the agent on use.
  home.sessionVariables = lib.mkIf (config.my.os == "wsl") {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  };

  # One OpenSSH agent with a stable socket. ssh-agent does not support systemd
  # socket activation, so the service owns the socket itself.
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

  # Preload selected identities after KDE has started the PAM wallet unlock.
  systemd.user.services.ssh-add-identities = lib.mkIf (nativeKde && selectedIdentities != { }) {
    Unit = {
      Description = "Load SSH identities into agent";
      After = [
        "ssh-agent.service"
        "plasma-kwallet-pam.service"
        "plasma-workspace.target"
        "graphical-session.target"
      ];
      Wants = [ "ssh-agent.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent.socket"
        "SSH_ASKPASS=/usr/bin/ksshaskpass"
        "SSH_ASKPASS_REQUIRE=prefer"
      ];
      StandardInput = "null";
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
        "DBUS_SESSION_BUS_ADDRESS"
        "KDE_FULL_SESSION"
        "XDG_CURRENT_DESKTOP"
      ];
      TimeoutStartSec = "60";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = identitySettings // {
      workstation = {
        HostName = "workstation.home.arpa";
        User = "simon";
      };
    };
  };

  home.file = lib.mkMerge [
    {
      ".ssh/config".force = true;
    }
    (lib.mapAttrs' (name: id: {
      name = ".ssh/${id.sshKeyFile}.pub";
      value = {
        text = id.sshPublicKey + "\n";
      };
    }) (lib.filterAttrs (_: id: (id.sshPublicKey or "") != "") selectedIdentities))
  ];

  home.activation.fixSshPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -d -m 0700 "$HOME/.ssh"
    if [ -L "$HOME/.ssh/config" ]; then
      src="$(readlink -f "$HOME/.ssh/config")"
      run rm -f "$HOME/.ssh/config"
      run install -m 0600 "$src" "$HOME/.ssh/config"
    fi
  '';
}
