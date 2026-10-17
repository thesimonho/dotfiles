{ lib }:

let
  inherit (lib) mkOption types;
  nativeLib = import ./native-packages.nix { inherit lib; };

  requirementType =
    requirementValues:
    types.submodule {
      options = {
        systems = mkOption {
          type = types.listOf (types.enum requirementValues.systems);
          default = [ ];
          description = "Nix systems on which this catalog entry is available.";
        };
        operatingSystems = mkOption {
          type = types.listOf (types.enum requirementValues.operatingSystems);
          default = [ ];
          description = "Host operating-system identities on which this entry is available.";
        };
        desktops = mkOption {
          type = types.listOf (types.enum requirementValues.desktops);
          default = [ ];
          description = "Desktop environments on which this entry is available.";
        };
        hasDesktop = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether this entry requires a graphical desktop session.";
        };
        gpuBackends = mkOption {
          type = types.listOf (types.enum requirementValues.gpuBackends);
          default = [ ];
          description = "GPU backends on which this entry is available.";
        };
      };
    };

  contributionType = types.submodule {
    options = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Nix packages installed when this entry is enabled.";
      };
      nativePackages = mkOption {
        type = nativeLib.mappingType;
        default = { };
        description = "Platform-specific native package installation mappings.";
      };
      programs = mkOption {
        type = types.attrs;
        default = { };
        description = "Home Manager programs configuration contributed by this entry.";
      };
      services = mkOption {
        type = types.attrs;
        default = { };
        description = "Home Manager systemd user services contributed by this entry.";
      };
      homeFiles = mkOption {
        type = types.attrs;
        default = { };
        description = "Home Manager home.file entries contributed by this entry.";
      };
      xdgConfigFiles = mkOption {
        type = types.attrs;
        default = { };
        description = "Home Manager xdg.configFile entries contributed by this entry.";
      };
      sessionVariables = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables contributed by this entry.";
      };
      shellAliases = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Zsh aliases contributed by this entry.";
      };
      activation = mkOption {
        type = types.attrs;
        default = { };
        description = "Home Manager activation DAG entries contributed by this entry.";
      };
    };
  };

  matchesAllowedValues =
    allowedValues: actualValue: allowedValues == [ ] || lib.elem actualValue allowedValues;

  describeAllowedValues =
    label: allowedValues: actualValue:
    lib.optional (
      !matchesAllowedValues allowedValues actualValue
    ) "${label} '${actualValue}' is not one of: ${lib.concatStringsSep ", " allowedValues}";

  requirementFailures =
    hostContext: requirements:
    describeAllowedValues "system" requirements.systems hostContext.system
    ++
      describeAllowedValues "operating system" requirements.operatingSystems
        hostContext.operatingSystem
    ++ describeAllowedValues "desktop" requirements.desktops hostContext.desktop
    ++ describeAllowedValues "GPU backend" requirements.gpuBackends hostContext.gpuBackend
    ++ lib.optional (
      requirements.hasDesktop != null && requirements.hasDesktop != hostContext.hasDesktop
    ) "requires hasDesktop=${lib.boolToString requirements.hasDesktop}";

  contributionHasValues =
    contributions:
    lib.any (value: value != [ ] && value != { }) (
      lib.attrValues (builtins.removeAttrs contributions [ "nativePackages" ])
    )
    || nativeLib.hasValues contributions.nativePackages;
in
{
  # Both sections share one selection namespace; reject accidental shadowing.
  mergeSections =
    { applications, support, ... }:
    let
      duplicates = lib.intersectLists (lib.attrNames applications) (lib.attrNames support);
    in
    if duplicates != [ ] then
      throw "Catalog names must be unique across applications and support: ${lib.concatStringsSep ", " duplicates}"
    else
      applications // support;

  /**
    Build the typed shape shared by every catalog domain.

    Domain-specific options, such as an app catalog's Flatpak declaration,
    remain explicit extensions rather than entering the generic contribution
    contract before another domain needs them.
  */
  mkCatalogType =
    {
      bundleNames,
      extraOptions ? { },
      requirementValues,
    }:
    types.attrsOf (
      types.submodule {
        options = {
          bundles = mkOption {
            type = types.listOf (types.enum bundleNames);
            default = [ ];
            description = "Bundle tags that select this catalog entry.";
          };
          requirements = mkOption {
            type = requirementType requirementValues;
            default = { };
            description = "Declarative host requirements for this catalog entry.";
          };
          contributions = mkOption {
            type = contributionType;
            default = { };
            description = "Typed Home Manager and native package contributions from this entry.";
          };
        }
        // extraOptions;
      }
    );

  /**
    Select entries and partition them by their compatibility with one host.

    Rejected entries retain their requirement failures so callers and checks
    can explain why a requested application was not realized.
  */
  resolveCatalog =
    {
      catalog,
      bundles,
      enabled,
      hostContext,
      disabled ? [ ],
    }:
    let
      enabledNames = lib.unique (
        (lib.filter (name: lib.any (bundle: lib.elem bundle catalog.${name}.bundles) bundles) (
          lib.attrNames catalog
        ))
        ++ enabled
      );
      selectedEntries = lib.filterAttrs (
        name: _: lib.elem name enabledNames && !lib.elem name disabled
      ) catalog;
      failuresByName = lib.mapAttrs (
        _: entry: requirementFailures hostContext entry.requirements
      ) selectedEntries;
      applicableEntries = lib.filterAttrs (name: _: failuresByName.${name} == [ ]) selectedEntries;
      rejectedEntries = lib.mapAttrs (name: entry: {
        inherit entry;
        reasons = failuresByName.${name};
      }) (lib.filterAttrs (name: _: failuresByName.${name} != [ ]) selectedEntries);
    in
    {
      inherit
        applicableEntries
        enabledNames
        rejectedEntries
        selectedEntries
        ;
    };

  /**
    Turn applicable catalog entries into mergeable Home Manager and native package configuration.
  */
  realizeContributions =
    { entries, domain }:
    let
      contributions = map (entry: entry.contributions) (lib.attrValues entries);
      mergeContributionField =
        field: lib.mkMerge (map (contribution: contribution.${field}) contributions);
    in
    {
      my.nativePackages.catalog = lib.mapAttrs' (name: entry: {
        name = "${domain}.${name}";
        value = entry.contributions.nativePackages;
      }) (lib.filterAttrs (_: entry: nativeLib.hasValues entry.contributions.nativePackages) entries);
      home = {
        packages = lib.unique (lib.concatMap (contribution: contribution.packages) contributions);
        file = mergeContributionField "homeFiles";
        sessionVariables = mergeContributionField "sessionVariables";
        activation = mergeContributionField "activation";
      };
      programs = lib.mkMerge (
        (map (contribution: contribution.programs) contributions)
        ++ [ { zsh.shellAliases = mergeContributionField "shellAliases"; } ]
      );
      systemd.user.services = mergeContributionField "services";
      xdg.configFile = mergeContributionField "xdgConfigFiles";
    };

  /**
    Whether an entry contributes through at least one generic channel.
  */
  hasContributions = entry: contributionHasValues entry.contributions;
}
