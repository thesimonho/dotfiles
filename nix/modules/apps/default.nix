{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkOption types mkIf;

  catalogLib = import ../../lib/catalog.nix { inherit lib; };

  dotfiles = config.my.dotfilesPath;
  symlinkConfig = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${name}";
    force = true;
  };

  catalogData = import ./catalog.nix { inherit pkgs symlinkConfig; };
  inherit (catalogData) bundleNames;

  flatpakOverrideType = types.submodule {
    options = {
      id = mkOption {
        type = types.str;
        description = "Flatpak app id (e.g. com.discordapp.Discord).";
      };
      overrides = mkOption {
        type = types.attrs;
        default = { };
        description = "Per-app override block passed to services.flatpak.overrides.";
      };
    };
  };

  programType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "home-manager program key (programs.<name>.enable = true).";
      };
      settings = mkOption {
        type = types.attrs;
        default = { };
        description = "Extra options merged into programs.<name>.";
      };
    };
  };

  appType = catalogLib.mkCatalogType {
    inherit bundleNames;
    extraOptions = {
      flatpak = mkOption {
        type = types.nullOr flatpakOverrideType;
        default = null;
      };
      program = mkOption {
        type = types.nullOr programType;
        default = null;
      };
    };
  };
  catalog = catalogData.entries;

  resolvedCatalog = config.my.apps.catalog;

  enabledNames = catalogLib.resolveEnabled {
    catalog = resolvedCatalog;
    bundles = config.my.apps.bundles;
    enabled = config.my.apps.enabled;
  };
  enabledEntries = lib.filterAttrs (n: _: lib.elem n enabledNames) resolvedCatalog;

  packageEntries = lib.filterAttrs (_: e: e.package != null) enabledEntries;
  flatpakEntries = lib.filterAttrs (_: e: e.flatpak != null) enabledEntries;
  programEntries = lib.filterAttrs (_: e: e.program != null) enabledEntries;

  hasAnyFlatpak = flatpakEntries != { };
  isLinux = config.my.os != "darwin";

  programsConfig = lib.listToAttrs (
    lib.mapAttrsToList (_: e: {
      name = e.program.name;
      value = {
        enable = true;
      }
      // e.program.settings;
    }) programEntries
  );

  flatpakIds = lib.mapAttrsToList (_: e: e.flatpak.id) flatpakEntries;
  flatpakOverrides = lib.listToAttrs (
    lib.concatMap (
      e:
      lib.optional (e.flatpak.overrides != { }) {
        name = e.flatpak.id;
        value = e.flatpak.overrides;
      }
    ) (lib.attrValues flatpakEntries)
  );

  mergeField =
    field:
    catalogLib.mergeField {
      entries = enabledEntries;
      inherit field;
    };

  mergedShellAliases = mergeField "shellAliases";
  mergedFiles = mergeField "files";
  mergedXdgConfigFiles = mergeField "xdgConfigFiles";
  mergedSessionVariables = mergeField "sessionVariables";
  mergedServices = mergeField "services";
  mergedActivation = mergeField "activation";
in
{
  options.my.apps = {
    bundles = mkOption {
      type = types.listOf (types.enum bundleNames);
      default = [ ];
      description = "App bundles enabled on this host.";
    };
    enabled = mkOption {
      type = types.listOf (types.enum (lib.attrNames catalog));
      default = [ ];
      description = "Individually enabled catalog entries (in addition to bundles).";
    };
    catalog = mkOption {
      type = appType;
      default = catalog;
      internal = true;
      description = "Internal: the resolved app catalog.";
    };
  };

  config = {
    assertions = lib.mapAttrsToList (name: e: {
      assertion = e.package != null || e.flatpak != null || e.program != null || e.shellAliases != { };
      message = "App catalog entry '${name}' must contribute at least one of package / flatpak / program / shellAliases.";
    }) resolvedCatalog;

    home = {
      packages = lib.mapAttrsToList (_: e: e.package) packageEntries;
      file = mergedFiles;
      sessionVariables = mergedSessionVariables;
      activation = mergedActivation;
    };

    systemd.user.services = mergedServices;

    programs = programsConfig // {
      zsh.shellAliases = mergedShellAliases;
    };

    services.flatpak = mkIf (isLinux && hasAnyFlatpak) {
      enable = true;
      uninstallUnmanaged = true;
      remotes = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      update = {
        onActivation = true;
        auto = {
          enable = true;
          onCalendar = "weekly";
        };
      };
      packages = flatpakIds;
      overrides = flatpakOverrides;
    };

    xdg.systemDirs.data = mkIf (isLinux && hasAnyFlatpak) [
      "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
    ];

    xdg.configFile =
      mergedXdgConfigFiles
      // lib.optionalAttrs (isLinux && hasAnyFlatpak) {
        "environment.d/20-flatpak.conf" = {
          text = "XDG_DATA_DIRS=$XDG_DATA_DIRS:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
        };
      };
  };
}
