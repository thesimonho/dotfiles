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

  catalogData = import ./catalog.nix {
    inherit
      inputs
      pkgsUnstable
      system
      ;
  };
  inherit (catalogData) bundleNames;
  catalog = catalogData.entries;

  catalogLib = import ../../lib/catalog.nix { inherit lib; };
  hostContextLib = import ../../lib/host-context.nix;
  aiType = catalogLib.mkCatalogType {
    inherit bundleNames;
    inherit (hostContextLib) requirementValues;
  };

  hostContext = hostContextLib.fromConfig { inherit config pkgs; };
  selection = catalogLib.resolveCatalog {
    catalog = config.my.ai.catalog;
    bundles = config.my.ai.bundles;
    enabled = config.my.ai.enabled;
    inherit hostContext;
  };
  enabledEntries = selection.applicableEntries;
in
{
  imports = [
    ./instructions.nix
    ./agents.nix
    ./skills.nix
    ./clients.nix
    ./llama.nix
  ];

  options.my.ai = {
    bundles = mkOption {
      type = types.listOf (types.enum bundleNames);
      default = [ ];
      description = "AI bundles to enable on this host (agents / cli / etc.).";
    };
    enabled = mkOption {
      type = types.listOf (types.enum (lib.attrNames catalog));
      default = [ ];
      description = "Individually enabled AI catalog entries (in addition to bundles).";
    };
    catalog = mkOption {
      type = aiType;
      default = catalog;
      internal = true;
      description = "Internal resolved AI catalog.";
    };
  };

  config = lib.mkMerge [
    (catalogLib.realizeContributions enabledEntries)
    {
      assertions = lib.mapAttrsToList (name: entry: {
        assertion = catalogLib.hasContributions entry;
        message = "Applicable AI catalog entry '${name}' must contribute a package or Home Manager configuration.";
      }) enabledEntries;
    }
  ];
}
