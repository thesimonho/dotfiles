{
  config,
  lib,
  pkgs,
  ...
}:
let
  mac = config.my.os == "darwin";

in
{
  options.my.onepassword = {
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

  config.home.packages =
    lib.mkIf (builtins.hasAttr "apps.1password" config.my.nativePackages.catalog)
      [
        (pkgs.writeShellScriptBin "with-secrets" ''
          if [ "$#" -eq 1 ] && [ "$1" = "--help" ]; then
            printf '%s\n' 'Usage: with-secrets ENVIRONMENT_ID COMMAND [ARG...]' \
              'Run a command with variables from a 1Password Environment.'
            exit 0
          fi
          if [ "$#" -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
            printf '%s\n' 'Usage: with-secrets ENVIRONMENT_ID COMMAND [ARG...]' >&2
            exit 2
          fi
          environment_id="$1"
          shift
          exec ${lib.escapeShellArg config.my.onepassword.cliPath} run --environment "$environment_id" -- "$@"
        '')
      ];

  config.programs.zsh.initContent = lib.mkIf (builtins.hasAttr "apps.1password" config.my.nativePackages.catalog) (
    lib.mkAfter ''
      if [[ -r "''${OP_CONFIG_DIR:-${config.xdg.configHome}/op}/plugins.sh" ]]; then
        source "''${OP_CONFIG_DIR:-${config.xdg.configHome}/op}/plugins.sh"
      fi
    ''
  );

}
