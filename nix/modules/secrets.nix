# KDE secrets resolve through fnox and KWallet without plaintext staging.
# Other platforms retain agenix activation and file-based recovery.
{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  inputs,
  ...
}:

let
  nativeKde = config.my.os != "darwin" && config.my.os != "wsl" && config.my.desktop == "kde";
  sshDir = "${config.home.homeDirectory}/.ssh";
  secretsDir = "${config.home.homeDirectory}/.secrets";
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
      fnox = "${pkgsUnstable.fnox}/bin/fnox";
      age = "${pkgs.age}/bin/age";
      sshAdd = "${pkgs.openssh}/bin/ssh-add";
      dbusUpdate = "${pkgs.dbus}/bin/dbus-update-activation-environment";
      isolatedConfig = "${pkgs.emptyDirectory}";
      inherit identityConfig globalKeys;
      globalConfig =
        if selectedSecrets ? api-keys then globalConfig else pkgs.writeText "empty-fnox.toml" "";
      sshKeys = lib.mapAttrsToList (name: id: {
        encrypted = builtins.toPath "${../secrets}/${id.sshKeyFile}.age";
        askpass = pkgs.writeShellScript "ssh-askpass-${name}" ''
          exec /usr/bin/ksshaskpass ${lib.escapeShellArg "Enter passphrase for ${sshDir}/${id.sshKeyFile}: "}
        '';
      }) selectedIdentities;
    }
  );
  sessionSecrets = pkgs.writeShellScriptBin "session-secrets" ''
    exec ${pkgs.python3}/bin/python3 ${../scripts/session-secrets.py} ${settings} "$@"
  '';

  # SSH keys from identities → ~/.ssh/
  sshSecrets = lib.mapAttrs' (name: id: {
    name = "identity-ssh-${name}";
    value = {
      file = builtins.toPath "${../secrets}/${id.sshKeyFile}.age";
      path = "${sshDir}/${id.sshKeyFile}";
      mode = "600";
      symlink = false;
    };
  }) selectedIdentities;

  # Non-identity secrets → ~/.secrets/
  otherSecrets = lib.mapAttrs' (name: info: {
    name = name;
    value = {
      file = builtins.toPath "${../secrets}/${info.file}.age";
      path = "${secretsDir}/${info.file}";
      symlink = false;
    };
  }) selectedSecrets;
in
{
  home.packages =
    with pkgs;
    [ age ]
    ++ lib.optionals (!nativeKde) [
      inputs.agenix.packages.${stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals nativeKde [
      sessionSecrets
      pkgsUnstable.fnox
    ];

  xdg.configFile."fnox/config.toml" = lib.mkIf (nativeKde && selectedSecrets ? api-keys) {
    source = globalConfig;
  };

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

  age = {
    identityPaths = lib.optionals (!nativeKde) [ "${secretsDir}/age_identity" ];
    secrets = lib.mkIf (!nativeKde) (sshSecrets // otherSecrets);
  };
}
