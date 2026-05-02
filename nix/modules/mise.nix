{
  config,
  pkgsUnstable,
  lib,
  ...
}:

let
  inherit (lib) mkOption types;
in
{
  options.my.mise.trustedPaths = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Additional mise trusted_config_paths entries appended on this host.";
  };

  config.programs.mise = {
    enable = true;
    package = pkgsUnstable.mise;
    globalConfig = {
      tools = {
        node = "24";
        python = "3.14.4";
        go = "1.25";
        rust = "1.92";
      };
      settings = {
        env_file = ".env";
        trusted_config_paths = [ "~" ] ++ config.my.mise.trustedPaths;
        idiomatic_version_file_enable_tools = [
          "node"
          "go"
          "python"
          "terraform"
        ];
        auto_install = true;
        not_found_auto_install = true;
        status = {
          missing_tools = "if_other_versions_installed";
          show_env = false;
          show_tools = false;
        };
        python.uv_venv_auto = "create|source";
      };
    };
  };
}
