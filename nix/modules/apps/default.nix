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
    inherit lib;
    inherit
      pkgs
      pkgsUnstable
      pkgsPinned
      symlinkConfig
      ;
  };
  inherit (catalogData) bundleNames;
  catalog = catalogLib.mergeSections catalogData;

  flatpakOverrideType = types.submodule {
    options = {
      id = mkOption {
        type = types.str;
        description = "Flatpak app id (e.g. com.discordapp.Discord).";
      };
      remote = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              name = mkOption { type = types.str; };
              location = mkOption { type = types.str; };
            };
          }
        );
        default = null;
        description = "Flatpak remote to add and install the app from, when specified.";
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
    disabled = config.my.apps.disabled;
    inherit hostContext;
  };
  enabledEntries = selection.applicableEntries;

  flatpakEntries = lib.filterAttrs (_: entry: entry.flatpak != null) enabledEntries;
  hasAnyFlatpak = flatpakEntries != { };
  isLinux = config.my.os != "darwin";
  flatpakActive = isLinux && hostContext.hasDesktop && hasAnyFlatpak;

  flatpakRemotes = lib.unique (
    [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ]
    ++ lib.concatMap (entry: lib.optional (entry.flatpak.remote != null) entry.flatpak.remote) (
      lib.attrValues flatpakEntries
    )
  );
  flatpakPackages = lib.mapAttrsToList (
    _: entry:
    if entry.flatpak.remote == null then
      entry.flatpak.id
    else
      {
        appId = entry.flatpak.id;
        origin = entry.flatpak.remote.name;
      }
  ) flatpakEntries;
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
    disabled = mkOption {
      type = types.listOf (types.enum (lib.attrNames catalog));
      default = [ ];
      description = "Catalog entries excluded from this host, including bundle members.";
    };
    catalog = mkOption {
      type = appType;
      internal = true;
      description = "Internal resolved app catalog.";
    };
  };

  config = lib.mkMerge [
    (catalogLib.realizeContributions {
      entries = enabledEntries;
      domain = "apps";
    })
    {
      # Module definitions let hosts override one entry without replacing
      # the complete catalog (an option default would be discarded).
      my.apps.catalog = catalog;
      assertions =
        lib.mapAttrsToList (name: entry: {
          assertion = catalogLib.hasContributions entry || entry.flatpak != null;
          message = "App catalog entry '${name}' must contribute a package, Home Manager configuration, or Flatpak.";
        }) resolvedCatalog
        ++ [
          {
            assertion =
              lib.length flatpakRemotes == lib.length (lib.unique (map (remote: remote.name) flatpakRemotes));
            message = "Flatpak remotes with the same name must have the same location.";
          }
        ];

      services.flatpak = mkIf flatpakActive {
        enable = true;
        uninstallUnmanaged = true;
        remotes = flatpakRemotes;
        update = {
          onActivation = true;
          auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };
        packages = flatpakPackages;
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
