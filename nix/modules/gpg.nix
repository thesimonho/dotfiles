# GPG key management and agent configuration.
# Public key and secret key are sourced from secrets/meta.nix and agenix respectively.
# Pinentry integrates with the system keyring (KWallet on Linux, Keychain on macOS).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  meta = import ../secrets/meta.nix;
in
{
  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        text = meta.publicKeys.gpg;
        trust = "ultimate";
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableExtraSocket = true;
    grabKeyboardAndMouse = true;
    pinentry.package = if isLinux then pkgs.pinentry-qt else pkgs.pinentry_mac;
    defaultCacheTtl = 86400; # 24 hours
    maxCacheTtl = 604800; # 7 days
  };

  # Import the agenix-decrypted secret key into the GPG keyring on activation
  home.activation = {
    importGpgSecretKey = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      secretKeyFile="$HOME/.secrets/gpg-secret"
      if [ -f "$secretKeyFile" ]; then
        run ${pkgs.gnupg}/bin/gpg --batch --import "$secretKeyFile" 2>/dev/null || true
      fi
    '';
  };
}
