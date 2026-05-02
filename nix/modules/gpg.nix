# GPG key management and agent configuration.
# Keys are derived from identities in secrets/meta.nix that have gpg config.
# Pinentry integrates with the system keyring (KWallet on Linux, Keychain on macOS).
{
  config,
  pkgs,
  lib,
  ...
}:

let
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
    enableExtraSocket = true;
    grabKeyboardAndMouse = true;
    noAllowExternalCache = false; # Allow pinentry-qt to save passphrases in KWallet
    pinentry.package = pinentryFor {
      os = config.my.os;
      desktop = config.my.desktop;
    };
    defaultCacheTtl = 86400; # 24 hours
    maxCacheTtl = 604800; # 7 days
    extraConfig = "allow-preset-passphrase";
  };

  # Import agenix-decrypted secret keys into the GPG keyring on activation
  home.activation = {
    importGpgSecretKey = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      let
        importCommands = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: id: ''
            secretKeyFile="$HOME/.secrets/${id.gpg.secretFile}"
            if [ -f "$secretKeyFile" ]; then
              run ${pkgs.gnupg}/bin/gpg --batch --import "$secretKeyFile" 2>&1 || true
            fi
          '') gpgIdentities
        );
      in
      importCommands
    );
  };
}
