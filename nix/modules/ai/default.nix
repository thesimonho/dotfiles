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
  dotfiles = config.my.dotfilesPath;
  symlinkConfig = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${name}";
    force = true;
  };

  catalogData = import ./catalog.nix {
    inherit
      inputs
      pkgsUnstable
      pkgs
      system
      symlinkConfig
      ;
  };
  inherit (catalogData) bundleNames;
  catalog = catalogLib.mergeSections catalogData;

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
    disabled = config.my.ai.disabled;
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
    disabled = mkOption {
      type = types.listOf (types.enum (lib.attrNames catalog));
      default = [ ];
      description = "Catalog entries excluded from this host, including bundle members.";
    };
    catalog = mkOption {
      type = aiType;
      internal = true;
      description = "Internal resolved AI catalog.";
    };
  };

  config = lib.mkMerge [
    (catalogLib.realizeContributions {
      entries = enabledEntries;
      domain = "ai";
    })
    {
      my.ai.catalog = catalog;
      assertions = lib.mapAttrsToList (name: entry: {
        assertion = catalogLib.hasContributions entry;
        message = "Applicable AI catalog entry '${name}' must contribute a package or Home Manager configuration.";
      }) enabledEntries;
    }
  ];
}
