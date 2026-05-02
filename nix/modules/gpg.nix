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
  meta = import ../secrets/meta.nix;

  selectedIdentities = lib.filterAttrs (name: _: lib.elem name config.my.identities) meta.identities;

  # Pick a pinentry that fits the host's DE / OS. KDE → Qt; macOS → Keychain
  # bridge; everything else → curses (works in any TTY).
  pinentryFor =
    { os, desktop }:
    if desktop == "kde" then
      pkgs.pinentry-qt
    else if os == "darwin" then
      pkgs.pinentry_mac
    else
      pkgs.pinentry-curses;

  # Collect GPG public keys from selected identities that have GPG config
  gpgIdentities = lib.filterAttrs (name: id: id.gpg != null) selectedIdentities;
  gpgPublicKeys = lib.mapAttrsToList (
    name: id: {
      text = id.gpg.publicKey;
      trust = "ultimate";
    }
  ) gpgIdentities;
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
          lib.mapAttrsToList (
            name: id: ''
              secretKeyFile="$HOME/.secrets/${id.gpg.secretFile}"
              if [ -f "$secretKeyFile" ]; then
                run ${pkgs.gnupg}/bin/gpg --batch --import "$secretKeyFile" 2>&1 || true
              fi
            ''
          ) gpgIdentities
        );
      in
      importCommands
    );
  };
}
