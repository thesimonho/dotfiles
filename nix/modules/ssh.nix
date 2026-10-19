# SSH agent, key loading, and host configuration.
# Match blocks are derived from identities in secrets/meta.nix.
# Secret key decryption is handled by secrets.nix.
#
# KDE uses native ksshaskpass; other Linux hosts retain libsecret helpers.
# Native mode keeps the legacy helpers available through the KDE rollback option.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = config.my.os != "darwin";
  isWSL = config.my.os == "wsl";
  isKde = config.my.desktop == "kde";
  nativeKde = config.my.os == "arch" && isKde && config.my.kdeNativeAuth;
  sshDir = "${config.home.homeDirectory}/.ssh";
  selectedIdentities = config.my._identities;

  # Derive SSH settings from identities
  identitySettings = lib.mapAttrs' (name: id: {
    name = id.sshHost;
    value = {
      HostName = id.sshProxyHost;
      Port = id.sshPort;
      User = "git";
      AddKeysToAgent = "true";
      ForwardAgent = true;
      IdentitiesOnly = true;
      IdentityFile = "${sshDir}/${id.sshKeyFile}";
    };
  }) selectedIdentities;

  sshKeyPaths = lib.concatStringsSep " " (
    lib.mapAttrsToList (_: id: "${sshDir}/${id.sshKeyFile}") selectedIdentities
  );

  # secret-askpass — libsecret-backed SSH_ASKPASS (lookup/store + GUI prompt).
  # coreutils pins sha1sum/cut/head used for the per-key retry marker; secret-
  # tool and the GUI prompters still resolve from the ambient PATH.
  secretAskpassApp = pkgs.writeShellApplication {
    name = "secret-askpass";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ../scripts/secret-askpass.sh;
  };
  # ssh-add-keys — preload identity keys into the agent (the login entrypoint).
  sshAddKeysApp = pkgs.writeShellApplication {
    name = "ssh-add-keys";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      SSH_KEY_PATHS=${lib.escapeShellArg sshKeyPaths}
      ${builtins.readFile ../scripts/ssh-add-keys.sh}
    '';
  };
  # ssh-keys — inspect/clear stored passphrases (parallels gpg-keys).
  sshKeysApp = pkgs.writeShellApplication {
    name = "ssh-keys";
    text = ''
      SSH_KEY_PATHS=${lib.escapeShellArg sshKeyPaths}
      ${builtins.readFile ../scripts/ssh-keys.sh}
    '';
  };

  askpassPath =
    if nativeKde then "/usr/bin/ksshaskpass" else "${secretAskpassApp}/bin/secret-askpass";
in
{
  assertions = [
    {
      assertion =
        !config.my.kdeNativeAuth
        || (nativeKde && builtins.hasAttr "apps.kde-authentication" config.my.nativePackages.catalog);
      message = "kdeNativeAuth requires Arch KDE and the security bundle's native authentication packages.";
    }
  ];

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

  # Preload selected identities at graphical login. KDE calls ssh-add directly;
  # the legacy loader remains for other Linux hosts and migration rollback.
  #
  # Excluded on WSL: graphical-session.target never fires there, so this unit
  # would install but never run. WSL drives the preload from the zsh
  # _preload_agent_once hook instead (the ssh-add-keys binary is still
  # installed via home.packages below).
  systemd.user.services.ssh-add-keys = lib.mkIf (isLinux && !isWSL && selectedIdentities != { }) {
    Unit = {
      Description = "Load SSH keys into agent";
      # Plasma's workspace starts the PAM unlock helper. Order after it,
      # without pulling it in again during a later Home Manager activation.
      After = [
        "ssh-agent.service"
        "graphical-session.target"
      ]
      ++ lib.optional isKde "plasma-kwallet-pam.service"
      ++ lib.optional nativeKde "plasma-workspace.target";
      Wants = [ "ssh-agent.service" ] ++ lib.optional (isKde && !nativeKde) "plasma-kwallet-pam.service";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent.socket"
        "SSH_ASKPASS=${askpassPath}"
        "SSH_ASKPASS_REQUIRE=prefer"
      ]
      ++ lib.optional (!nativeKde) "SSH_ASKPASS_DEFER=1";
      StandardInput = "null";
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
        "DBUS_SESSION_BUS_ADDRESS"
        "KDE_FULL_SESSION"
        "XDG_CURRENT_DESKTOP"
      ];
      ExecStart =
        if nativeKde then
          "${pkgs.openssh}/bin/ssh-add -q ${
            lib.concatMapStringsSep " " (id: lib.escapeShellArg "${sshDir}/${id.sshKeyFile}") (
              lib.attrValues selectedIdentities
            )
          }"
        else
          "${sshAddKeysApp}/bin/ssh-add-keys";
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
    settings = identitySettings // {
      workstation = {
        HostName = "workstation.home.arpa";
        User = "simon";
      };
    };
  };

  # secret-askpass / ssh-add-keys / ssh-keys are installed via home.packages
  # (below) since they're writeShellApplication derivations.
  home.packages = lib.mkIf (isLinux && !nativeKde) [
    secretAskpassApp
    sshAddKeysApp
    sshKeysApp
  ];

  # - ~/.ssh/config force flag (see https://github.com/nix-community/home-manager/issues/322)
  # - ~/.ssh/<key>.pub materialized from meta.nix
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

  home.activation = {
    # Native reconciliation runs after activation. Fail before replacing any
    # files if a fresh host has not installed the native tools yet.
    checkNativeKdeAuth = lib.mkIf nativeKde (
      lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        for tool in /usr/bin/ksshaskpass /usr/bin/pinentry-qt; do
          if [ ! -x "$tool" ]; then
            echo "Native KDE authentication requires $tool before activation. Install ksshaskpass and pinentry, then retry." >&2
            exit 1
          fi
        done
      ''
    );

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
