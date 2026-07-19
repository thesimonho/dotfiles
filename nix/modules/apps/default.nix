{
  config,
  pkgs,
  pkgsUnstable,
  pkgsPinned,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkOption types;

  catalogLib = import ../../lib/catalog.nix { inherit lib; };
  hostContextLib = import ../../lib/host-context.nix;

  dotfiles = config.my.dotfilesPath;
  symlinkConfig = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${name}";
    force = true;
  };

  catalogData = import ./catalog.nix {
    inherit
      pkgs
      pkgsUnstable
      pkgsPinned
      symlinkConfig
      ;
  };
  inherit (catalogData) bundleNames;
  catalog = catalogData.entries;

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

  appType = catalogLib.mkCatalogType {
    inherit bundleNames;
    inherit (hostContextLib) requirementValues;
    extraOptions.flatpak = mkOption {
      type = types.nullOr flatpakOverrideType;
      default = null;
    };
  };

  resolvedCatalog = config.my.apps.catalog;
  hostContext = hostContextLib.fromConfig { inherit config pkgs; };
  selection = catalogLib.resolveCatalog {
    catalog = resolvedCatalog;
    bundles = config.my.apps.bundles;
    enabled = config.my.apps.enabled;
    inherit hostContext;
  };
  enabledEntries = selection.applicableEntries;

  flatpakEntries = lib.filterAttrs (_: entry: entry.flatpak != null) enabledEntries;
  hasAnyFlatpak = flatpakEntries != { };
  isLinux = config.my.os != "darwin";
  flatpakActive = isLinux && hostContext.hasDesktop && hasAnyFlatpak;

  flatpakIds = lib.mapAttrsToList (_: entry: entry.flatpak.id) flatpakEntries;
  flatpakOverrides = lib.listToAttrs (
    lib.concatMap (
      entry:
      lib.optional (entry.flatpak.overrides != { }) {
        name = entry.flatpak.id;
        value = entry.flatpak.overrides;
      }
    ) (lib.attrValues flatpakEntries)
  );
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
      description = "Internal resolved app catalog.";
    };
  };

  config = lib.mkMerge [
    (catalogLib.realizeContributions enabledEntries)
    {
      assertions = lib.mapAttrsToList (name: entry: {
        assertion = catalogLib.hasContributions entry || entry.flatpak != null;
        message = "App catalog entry '${name}' must contribute a package, Home Manager configuration, or Flatpak.";
      }) resolvedCatalog;

      services.flatpak = mkIf flatpakActive {
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

      xdg.systemDirs.data = mkIf flatpakActive [
        "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
        "/var/lib/flatpak/exports/share"
      ];

      xdg.configFile = lib.mkIf flatpakActive {
        "environment.d/20-flatpak.conf" = {
          text = "XDG_DATA_DIRS=$XDG_DATA_DIRS:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
        };
      };
    }
  ];
}
