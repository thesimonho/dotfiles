{
  config,
  pkgs,
  pkgsUnstable,
  inputs,
  lib,
  ...
}:

let
  inherit (lib) mkOption types;
  system = pkgs.stdenv.hostPlatform.system;

  catalog = import ./catalog.nix { inherit inputs pkgsUnstable system; };
  catalogLib = import ../../lib/catalog.nix { inherit lib; };

  enabledNames = catalogLib.resolveEnabled {
    inherit catalog;
    bundles = config.my.ai.bundles;
    enabled = config.my.ai.enabled;
  };
  enabledEntries = lib.filterAttrs (n: _: lib.elem n enabledNames) catalog;

  bundleNames = [
    "cli-agents"
    "local-models"
    "tooling"
  ];
in
{
  imports = [
    ./shared.nix
    ./claude.nix
    ./llama.nix
  ];

  options.my.ai = {
    bundles = mkOption {
      type = types.listOf (types.enum bundleNames);
      default = [ ];
      description = "AI bundles to enable on this host (cli-agents / local-models / tooling).";
    };
    enabled = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Individually enabled AI catalog entries (in addition to bundles).";
    };
    claude.targetDir = mkOption {
      type = types.str;
      default = ".claude";
      description = "Target directory for Claude symlinks (e.g. .claude or .claude2).";
    };
  };

  config = {
    home.packages = lib.mapAttrsToList (_: e: e.package) (
      lib.filterAttrs (_: e: e.package != null) enabledEntries
    );
  };
}
