# GPG agent configuration and key import.
# Keys are derived from identities in secrets/meta.nix that have gpg config.
#
# Linux KDE uses pinentry-qt with KWallet; macOS keeps pinentry-mac. WSL uses
# pinentry-curses and keeps passphrases only in the agent's memory cache.
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
  terminalPinentry = config.services.gpg-agent.pinentry.package == pkgs.pinentry-curses;

  gpgPkg = pkgs.gnupg;
  gpgBin = "${gpgPkg}/bin/gpg";

  gpgIdentities = lib.filterAttrs (_: id: id.gpg != null) selectedIdentities;
  gpgPublicKeys = lib.mapAttrsToList (name: id: {
    text = id.gpg.publicKey;
    trust = "ultimate";
  }) gpgIdentities;

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
    enableZshIntegration = terminalPinentry;
    enableExtraSocket = true;
    grabKeyboardAndMouse = true;
    noAllowExternalCache = false;
    pinentry.package =
      if nativeKde then
        null
      else
        pinentryFor {
          os = config.my.os;
          desktop = config.my.desktop;
        };
    # KWallet persists the KDE passphrase, so let gpg-agent use its shorter
    # built-in cache limits. Other platforms use a 30-day memory cache.
    defaultCacheTtl = if nativeKde then null else 2592000;
    maxCacheTtl = if nativeKde then null else 2592000;
    extraConfig = lib.optionalString nativeKde "pinentry-program /usr/bin/pinentry-qt";
  };

  # Refresh the prompt destination after Home Manager exports GPG_TTY.
  programs.zsh.initContent = lib.mkIf terminalPinentry (
    lib.mkOrder 1100 ''
      if [[ -o interactive ]]; then
        ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
      fi
    ''
  );

  # Pinentry inherits this from the socket-activated agent even for GUI callers.
  systemd.user.services.gpg-agent.Service.Environment = lib.mkIf nativeKde [
    "PINENTRY_KDE_USE_WALLET=1"
  ];

  # Import encrypted backups directly; never retain decrypted export files.
  home.activation.importGpgSecretKey = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: id:
        let
          encryptedKey = builtins.toPath "${../secrets}/${id.gpg.secretFile}.age";
        in
        ''
          if [ -f "$HOME/.secrets/age_identity" ]; then
            run ${pkgs.bash}/bin/bash -euo pipefail -c \
              '${pkgs.age}/bin/age --decrypt --identity "$1" "$2" | ${gpgBin} --batch --import' \
              -- "$HOME/.secrets/age_identity" ${lib.escapeShellArg (toString encryptedKey)}
          fi
        ''
      ) (lib.filterAttrs (_: id: id.gpg ? secretFile) gpgIdentities)
    )
  );
}
