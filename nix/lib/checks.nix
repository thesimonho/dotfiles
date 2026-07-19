{
  lib,
  inputs,
  home-manager,
  sharedModules,
  pkgsFor,
  unstableFor,
  pinnedFor,
}:

let
  catalogLib = import ./catalog.nix { inherit lib; };
  hostContextLib = import ./host-context.nix;

  /*
    Build a home-manager configuration from inline modules. Mirrors mkHost
    in flake.nix but takes modules directly instead of reading hosts/<name>.nix.
  */
  mkSyntheticHost =
    {
      system,
      name,
      modules,
    }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor {
        inherit system;
        hostName = name;
      };
      extraSpecialArgs = {
        inherit inputs;
        pkgsUnstable = unstableFor {
          inherit system;
          hostName = name;
        };
        pkgsPinned = pinnedFor {
          inherit system;
          hostName = name;
        };
      };
      modules = sharedModules ++ modules;
    };

  /*
    Eval-only check derivation. Forces module evaluation (which triggers
    type checks like enum-on-bundles and the catalog-shape assertion) by
    serializing a digest of the resolved config. Does not build home.packages,
    just reads their names.
  */
  mkEvalCheck =
    system: hmConfig:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_check";
      };
      failed = builtins.filter (a: !a.assertion) hmConfig.config.assertions;
      digest = builtins.toJSON {
        packages = map (p: p.pname or p.name or "anon") hmConfig.config.home.packages;
        files = builtins.attrNames hmConfig.config.home.file;
        activation = builtins.attrNames hmConfig.config.home.activation;
      };
    in
    if failed != [ ] then
      throw "Assertions failed:\n  - ${lib.concatStringsSep "\n  - " (map (a: a.message) failed)}"
    else
      pkgs.writeText "eval-check.json" digest;

  /*
    Exercise catalog selection through its public interface. This keeps host
    applicability and rejected-entry diagnostics stable independently of any
    one domain dispatcher.
  */
  mkCatalogEngineCheck =
    system:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_catalog-check";
      };
      result = catalogLib.resolveCatalog {
        catalog.desktop = {
          bundles = [ "agents" ];
          requirements = {
            systems = [ "x86_64-linux" ];
            operatingSystems = [ ];
            desktops = [ ];
            hasDesktop = true;
            gpuBackends = [ ];
          };
        };
        bundles = [ "agents" ];
        enabled = [ ];
        hostContext = {
          inherit system;
          operatingSystem = "arch";
          desktop = "none";
          gpuBackend = "none";
          hasDesktop = false;
        };
      };
      digest = builtins.toJSON {
        applicable = builtins.attrNames result.applicableEntries;
        rejected = result.rejectedEntries.desktop.reasons;
      };
    in
    assert result.applicableEntries == { };
    assert result.rejectedEntries.desktop.reasons == [ "requires hasDesktop=true" ];
    pkgs.writeText "catalog-engine-check.json" digest;

  # Verify the shared requirement enums reject undeclared host identities.
  mkCatalogTypeCheck =
    system:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_catalog-type-check";
      };
      catalogType = catalogLib.mkCatalogType {
        bundleNames = [ "test" ];
        inherit (hostContextLib) requirementValues;
      };
      invalidCatalogEvaluation = builtins.tryEval (
        builtins.deepSeq
          (lib.evalModules {
            modules = [
              {
                options.catalog = lib.mkOption { type = catalogType; };
                config.catalog.invalid.requirements.operatingSystems = [ "undeclared-os" ];
              }
            ];
          }).config.catalog
          true
      );
    in
    assert !invalidCatalogEvaluation.success;
    pkgs.writeText "catalog-type-check.json" (builtins.toJSON { rejectsUnknownHostValues = true; });

  mkCodexDesktopCheck =
    {
      system,
      hmConfig,
      expected,
    }:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_codex-desktop-check";
      };
      actual = hmConfig.config.programs.codexDesktopLinux.enable;
    in
    assert actual == expected;
    pkgs.writeText "codex-desktop-check.json" (builtins.toJSON { inherit actual expected; });

  /*
    Synthetic host that enables every bundle. Catches catalog entries whose
    tagged bundle no real host happens to enable. Keep `apps.bundles` /
    `ai.bundles` in sync with the bundleNames lists in their catalogs.
  */
  kitchenSinkLinux = mkSyntheticHost {
    system = "x86_64-linux";
    name = "kitchen-sink";
    modules = [
      {
        my = {
          hostName = "kitchen-sink";
          os = "arch";
          desktop = "none";
          gpu.backend = "none";
          apps.bundles = [
            "cli"
            "security"
            "fonts"
            "communication"
            "dev"
            "cloud"
          ];
          ai.bundles = [
            "cli"
            "agents"
            "skills"
          ];
        };
        home = {
          username = "test";
          homeDirectory = "/home/test";
        };
      }
    ];
  };
in
{
  /*
    Build the `checks.<system>` attrset for `nix flake check`. Pass in the
    real homeConfigurations so each gets an eval-only check derivation.
  */
  mkChecks = homeConfigurations: {
    x86_64-linux = {
      catalog-engine = mkCatalogEngineCheck "x86_64-linux";
      catalog-types = mkCatalogTypeCheck "x86_64-linux";
      codex-desktop = mkCodexDesktopCheck {
        system = "x86_64-linux";
        hmConfig = homeConfigurations.desktop;
        expected = true;
      };
      codex-desktop-wsl = mkCodexDesktopCheck {
        system = "x86_64-linux";
        hmConfig = homeConfigurations.work-wsl;
        expected = false;
      };
      desktop = mkEvalCheck "x86_64-linux" homeConfigurations.desktop;
      work-wsl = mkEvalCheck "x86_64-linux" homeConfigurations.work-wsl;
      kitchen-sink = mkEvalCheck "x86_64-linux" kitchenSinkLinux;
    };
    aarch64-darwin = {
      codex-desktop = mkCodexDesktopCheck {
        system = "aarch64-darwin";
        hmConfig = homeConfigurations.work-macbook;
        expected = false;
      };
      work-macbook = mkEvalCheck "aarch64-darwin" homeConfigurations.work-macbook;
    };
  };
}
