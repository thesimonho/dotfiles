# GPG key management, agent configuration, and signing-passphrase persistence.
# Keys are derived from identities in secrets/meta.nix that have gpg config.
#
# Passphrase persistence (parallels modules/ssh.nix):
#   - macOS: pinentry-mac stores the passphrase in Keychain.
#   - Linux: the passphrase lives in libsecret (KWallet on KDE, gnome-keyring
#     elsewhere) and is re-injected into gpg-agent at login by the
#     gpg-preset-passphrases oneshot, so signed commits stop re-prompting
#     after every reboot / `wsl --shutdown`. The long cache TTLs below are
#     the in-memory backstop between those re-injections.
#
# Key divergence from SSH: `gpg-preset-passphrase` does NOT validate the
# value it's given (a bogus passphrase presets with exit 0, then fails only
# at sign time). SSH's askpass retry/self-heal has no GPG equivalent, so the
# helper test-signs throwaway data first and never stores or presets a value
# that won't actually sign.
#
# The helper scripts live in ../scripts and are wrapped with
# writeShellApplication (shellcheck at build time). runtimeInputs pins only
# the nix-provided tools (gpg/gpgconf); secret-tool and the GUI prompters
# (kdialog/zenity/notify-send) resolve from the ambient PATH, exactly as the
# SSH path does — writeShellApplication prepends runtimeInputs, it doesn't
# reset PATH.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = config.my.os != "darwin";
  isWSL = config.my.os == "wsl";
  selectedIdentities = config.my._identities;

  # Pinentry by (DE, OS). KDE → Qt + KWallet; macOS → Keychain bridge;
  # other Linux → curses (works in any TTY without DE assumptions).
  pinentryByDesktop = {
    kde = pkgs.pinentry-qt;
  };
  pinentryByOs = {
    darwin = pkgs.pinentry_mac;
  };
  pinentryFor =
    { os, desktop }: pinentryByDesktop.${desktop} or pinentryByOs.${os} or pkgs.pinentry-curses;

  gpgPkg = pkgs.gnupg;
  gpgBin = "${gpgPkg}/bin/gpg";

  gpgIdentities = lib.filterAttrs (_: id: id.gpg != null) selectedIdentities;
  gpgPublicKeys = lib.mapAttrsToList (name: id: {
    text = id.gpg.publicKey;
    trust = "ultimate";
  }) gpgIdentities;

  # Identities that sign commits: have a GPG block with sign enabled.
  # Matches the gpgSign wiring in git.nix; `sprung` (gpg = null) is excluded.
  signingIdentities = lib.filterAttrs (
    _: id: id.gpg != null && (id.gpg.sign or false)
  ) selectedIdentities;
  signingKeyIds = lib.concatStringsSep " " (
    lib.mapAttrsToList (_: id: id.gpg.keyId) signingIdentities
  );

  # Passphrase persistence only applies on Linux (macOS uses Keychain) and
  # only when something actually signs.
  enablePersistence = isLinux && signingIdentities != { };

  # gpg-preset <keyId> — the per-key primitive (resolve/validate/store/preset).
  gpgPresetApp = pkgs.writeShellApplication {
    name = "gpg-preset";
    runtimeInputs = [ gpgPkg ];
    text = builtins.readFile ../scripts/gpg-preset.sh;
  };
  # gpg-preset-driver — preset every signing identity (the login entrypoint).
  gpgPresetDriverApp = pkgs.writeShellApplication {
    name = "gpg-preset-driver";
    runtimeInputs = [ gpgPresetApp ];
    text = ''
      GPG_SIGNING_KEY_IDS=${lib.escapeShellArg signingKeyIds}
      ${builtins.readFile ../scripts/gpg-preset-driver.sh}
    '';
  };
  # gpg-keys — inspect/clear stored passphrases (parallels ssh-keys).
  gpgKeysApp = pkgs.writeShellApplication {
    name = "gpg-keys";
    text = ''
      GPG_SIGNING_KEY_IDS=${lib.escapeShellArg signingKeyIds}
      ${builtins.readFile ../scripts/gpg-keys.sh}
    '';
  };
in
{
  programs.gpg = {
    enable = true;
    publicKeys = gpgPublicKeys;
    settings = {
      quiet = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableExtraSocket = true;
    grabKeyboardAndMouse = true;
    noAllowExternalCache = false;
    pinentry.package = pinentryFor {
      os = config.my.os;
      desktop = config.my.desktop;
    };
    defaultCacheTtl = 2592000; # 30 days
    maxCacheTtl = 2592000; # 30 days
    extraConfig = "allow-preset-passphrase";
  };

  # Preset signing passphrases at login. Ordered on gpg-agent.socket (NOT
  # the service — it is `--supervised` with RefuseManualStart); the preset
  # binary socket-activates the agent. GNUPGHOME is pinned to match the
  # agent's own value so we preset into the same agent.
  #
  # Excluded on WSL: graphical-session.target never fires there, so this unit
  # would install but never run. WSL drives the preset from the zsh
  # _preload_agent_once hook instead (the gpg-preset-driver binary is still
  # installed via home.packages below).
  systemd.user.services.gpg-preset-passphrases = lib.mkIf (enablePersistence && !isWSL) {
    Unit = {
      Description = "Preset GPG signing passphrases into gpg-agent";
      After = [
        "gpg-agent.socket"
        "graphical-session.target"
      ];
      Wants = [ "gpg-agent.socket" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [ "GNUPGHOME=%h/.gnupg" ];
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
        "DBUS_SESSION_BUS_ADDRESS"
        "KDE_FULL_SESSION"
        "XDG_CURRENT_DESKTOP"
      ];
      ExecStart = "${gpgPresetDriverApp}/bin/gpg-preset-driver";
      # Cap so a hidden/hung GUI dialog can't stall `home-manager switch`.
      TimeoutStartSec = "60";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = lib.mkIf enablePersistence [
    gpgPresetApp
    gpgPresetDriverApp
    gpgKeysApp
  ];

  # Import agenix-decrypted secret keys into the GPG keyring on activation
  home.activation = {
    importGpgSecretKey = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      let
        importCommands = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: id: ''
            secretKeyFile="$HOME/.secrets/${id.gpg.secretFile}"
            if [ -f "$secretKeyFile" ]; then
              run ${gpgBin} --batch --import "$secretKeyFile" 2>&1 || true
            fi
          '') gpgIdentities
        );
      in
      importCommands
    );
  };
}
