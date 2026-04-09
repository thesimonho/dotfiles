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
  isLinux = pkgs.stdenv.isLinux;
  meta = import ../secrets/meta.nix;

  # Collect GPG public keys from all identities that have GPG config
  gpgIdentities = lib.filterAttrs (name: id: id.gpg != null) meta.identities;
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
  };

  services.gpg-agent = {
    enable = true;
    enableExtraSocket = true;
    grabKeyboardAndMouse = true;
    noAllowExternalCache = false; # Allow pinentry-qt to save passphrases in KWallet
    pinentry.package = if isLinux then pkgs.pinentry-qt else pkgs.pinentry_mac;
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
