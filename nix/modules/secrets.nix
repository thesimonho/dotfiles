# Native keyring adapters share fnox enrollment and streamed secret consumers.
{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

let
  nativeKde = config.my.os != "darwin" && config.my.os != "wsl" && config.my.desktop == "kde";
  sshDir = "${config.home.homeDirectory}/.ssh";
  selectedIdentities = config.my._identities;
  selectedSecrets = config.my._secrets;

  globalConfig = ../secrets/fnox.toml;
  globalKeys =
    if selectedSecrets ? api-keys then
      builtins.attrNames (builtins.fromTOML (builtins.readFile globalConfig)).secrets
    else
      [ ];
  identityConfig = pkgs.writeText "dotfiles-age-identity.toml" ''
    [providers.keychain]
    type = "keychain"
    service = "dotfiles-secrets"
    [secrets.AGE_IDENTITY]
    provider = "keychain"
    value = "age-identity"
  '';
  settings = pkgs.writeText "session-secrets.json" (
    builtins.toJSON {
      platform =
        if nativeKde then
          "kde"
        else if config.my.os == "darwin" then
          "macos"
        else
          "unsupported";
      fnox = "${pkgsUnstable.fnox}/bin/fnox";
      age = "${pkgs.age}/bin/age";
      ageKeygen = "${pkgs.age}/bin/age-keygen";
      ageRecipient = (import ../secrets/meta.nix).agePublicKey;
      keychainService = "dotfiles-secrets";
      sshAdd = if config.my.os == "darwin" then "/usr/bin/ssh-add" else "${pkgs.openssh}/bin/ssh-add";
      dbusUpdate = if nativeKde then "${pkgs.dbus}/bin/dbus-update-activation-environment" else null;
      isolatedConfig = "${pkgs.emptyDirectory}";
      inherit identityConfig globalKeys;
      globalConfig =
        if selectedSecrets ? api-keys then globalConfig else pkgs.writeText "empty-fnox.toml" "";
      sshKeys = lib.mapAttrsToList (
        name: id:
        {
          encrypted = builtins.toPath "${../secrets}/${id.sshKeyFile}.age";
        }
        // lib.optionalAttrs nativeKde {
          askpass = pkgs.writeShellScript "ssh-askpass-${name}" ''
            exec /usr/bin/ksshaskpass ${lib.escapeShellArg "Enter passphrase for ${sshDir}/${id.sshKeyFile}: "}
          '';
        }
      ) selectedIdentities;
    }
  );
  sessionSecrets = pkgs.writeShellScriptBin "session-secrets" ''
    exec ${pkgs.python3}/bin/python3 ${../scripts/session-secrets.py} ${settings} "$@"
  '';

in
{
  my._sessionSecrets = sessionSecrets;

  home.packages = [
    pkgs.age
    sessionSecrets
    pkgsUnstable.fnox
  ];

  xdg.configFile."fnox/config.toml" = lib.mkIf (selectedSecrets ? api-keys) {
    source = globalConfig;
  };

  # Prevent unsupported credential hosts from partially activating via direct HM.
  home.activation.checkSecretBackend =
    lib.mkIf (selectedIdentities != { } || selectedSecrets != { })
      (
        lib.hm.dag.entryBefore [ "writeBoundary" ] ''
          ${sessionSecrets}/bin/session-secrets check-platform
        ''
      );

  systemd.user.services.ssh-add-identities = lib.mkIf (nativeKde && selectedIdentities != { }) {
    Service.ExecStart = "${sessionSecrets}/bin/session-secrets ssh";
  };

  systemd.user.services.session-secrets = lib.mkIf nativeKde {
    Unit = {
      Description = "Import global secrets from KWallet into the desktop session";
      After = [ "plasma-kwallet-pam.service" ];
      Before = [
        "plasma-plasmashell.service"
        "plasma-kded6.service"
        "plasma-ksmserver.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${sessionSecrets}/bin/session-secrets environment";
      TimeoutStartSec = 30;
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "plasma-workspace.target" ];
  };

}
