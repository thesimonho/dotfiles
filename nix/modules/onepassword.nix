{
  config,
  lib,
  pkgs,
  ...
}:
let
  mac = config.my.os == "darwin";
  cfg = config.my.onepassword;
  providers = lib.mapAttrs (_: app: app.secrets.provides) cfg.applications;
  merge =
    maps:
    lib.foldl' (
      acc: values:
      lib.foldl' (
        result: key:
        if result ? ${key} && result.${key} != values.${key} then
          throw "Conflicting secret variable ${key}"
        else
          result // { ${key} = values.${key}; }
      ) acc (lib.attrNames values)
    ) { } maps;
  provider =
    name: if providers ? ${name} then providers.${name} else throw "Unknown secret provider ${name}";
  vault =
    name:
    if cfg.vaults ? ${name} then
      merge (map provider cfg.vaults.${name})
    else
      throw "Unknown secret vault ${name}";
  resolve =
    ref: if lib.hasPrefix "vault." ref then vault (lib.removePrefix "vault." ref) else provider ref;
  refsFor = app: merge ([ app.secrets.provides ] ++ map resolve app.secrets.requires);
  makeLauncher =
    name: refs:
    pkgs.writeShellScriptBin "with-secrets" ''
      exec ${pkgs.python3}/bin/python3 ${../scripts/with-secrets.py} \
        ${pkgs.writeText "${name}-references.json" (builtins.toJSON refs)} \
        ${lib.escapeShellArg cfg.cliPath} "$@"
    '';
  launchers = lib.mapAttrs (name: app: makeLauncher name (refsFor app)) cfg.applications;
  cliWrappers = lib.mapAttrsToList (
    name: app:
    lib.hiPrio (
      pkgs.writeShellScriptBin (baseNameOf app.command) ''
        exec ${launchers.${name}}/bin/with-secrets ${lib.escapeShellArg app.command} "$@"
      ''
    )
  ) (lib.filterAttrs (_: app: app.command != null && refsFor app != { }) cfg.applications);

in
{
  options.my.onepassword = {
    applications = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
      internal = true;
    };
    launchers = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = launchers;
      internal = true;
    };
    vaults = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
    };
    cliPath = lib.mkOption {
      type = lib.types.str;
      default =
        if mac then
          (if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew/bin/op" else "/usr/local/bin/op")
        else
          "/usr/bin/op";
      description = "Native 1Password CLI path for runtime secret injection.";
    };
    signerPath = lib.mkOption {
      type = lib.types.str;
      default =
        if mac then
          "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
          "/opt/1Password/op-ssh-sign";
      description = "Native 1Password SSH signer.";
    };
    agentSocket = lib.mkOption {
      type = lib.types.str;
      default =
        if mac then
          "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        else
          "${config.home.homeDirectory}/.1password/agent.sock";
      description = "Native 1Password SSH socket.";
    };
  };

  config.my.onepassword.vaults = {
    models = [
      "ai.codex"
      "ai.typesafe"
    ];
    developer-tools = [
      "apps.gh"
      "ai.huggingface-hub"
      "ai.wrangler"
    ];
  };
  config.home.packages = [
    (makeLauncher "all-vaults" (merge (map vault (lib.attrNames cfg.vaults))))
  ]
  ++ cliWrappers;
}
