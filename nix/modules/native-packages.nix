{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.nativePackages;
  nativeLib = import ../lib/native-packages.nix { inherit lib; };
  missing = lib.attrNames (
    lib.filterAttrs (
      _: mappings: cfg.platform == null || !nativeLib.hasValues mappings.${cfg.platform}
    ) cfg.catalog
  );
  selected = map (mappings: mappings.${cfg.platform}) (lib.attrValues cfg.catalog);
  collect = field: lib.sort builtins.lessThan (lib.unique (lib.concatMap field selected));
  repositories = lib.zipAttrsWith (
    name: values:
    if lib.all (value: value == builtins.head values) values then
      builtins.head values
    else
      throw "Conflicting native repository declarations for '${name}'."
  ) (map (mapping: mapping.dnf.repositories) selected);
  packages =
    if cfg.platform == "arch" then
      {
        pacman = collect (mapping: mapping.pacman);
        aur = collect (mapping: mapping.aur);
      }
    else if cfg.platform == "darwin" then
      {
        homebrewFormula = collect (mapping: mapping.homebrew.formulae);
        homebrewCask = collect (mapping: mapping.homebrew.casks);
      }
    else if cfg.platform == "fedora" then
      {
        dnf = collect (mapping: mapping.dnf.packages);
      }
    else
      { };
  aurBuilds = lib.zipAttrsWith (
    name: values:
    if lib.all (value: value == builtins.head values) values then
      builtins.head values
    else
      throw "Conflicting native AUR build commands for '${name}'."
  ) (map (mapping: mapping.aurBuilds) selected);
  manifest =
    if missing != [ ] then
      throw "Native package mappings missing for host '${config.my.hostName}' (platform ${
        if cfg.platform == null then "unset" else cfg.platform
      }): ${lib.concatStringsSep ", " missing}. Add a platform mapping or explicitly disable the application on this host."
    else
      {
        version = 5;
        host = config.my.hostName;
        os = config.my.os;
        platform = cfg.platform;
        system = pkgs.stdenv.hostPlatform.system;
        inherit packages;
        repositories = if cfg.platform == "fedora" then repositories else { };
        aurBuilds = if cfg.platform == "arch" then aurBuilds else { };
      };
  reconciler = pkgs.writeScriptBin "native-packages" (
    "#!${pkgs.python3}/bin/python3\n" + builtins.readFile ../scripts/native-packages.py
  );
in
{
  options.my.nativePackages = {
    catalog = lib.mkOption {
      type = lib.types.attrsOf nativeLib.mappingType;
      default = { };
      internal = true;
      description = "Applicable native package declarations, keyed by domain and application.";
    };
    platform = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "arch"
          "darwin"
          "fedora"
        ]
      );
      default = if config.my.os == "wsl" then null else config.my.os;
      description = "Native package platform. WSL requires an explicit Linux distro when native packages are selected.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      default = reconciler;
      description = "Native reconciler shared by Home Manager and preview commands.";
    };
    manifest = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      default = manifest;
      description = "Resolved host-native package inventory.";
    };
  };
  config = {
    assertions = [
      {
        assertion =
          lib.length (lib.concatLists (lib.attrValues manifest.packages))
          == lib.length (lib.unique (lib.concatLists (lib.attrValues manifest.packages)));
        message = "A native package name cannot use multiple backends on one host.";
      }
    ];
    home.packages = [ cfg.package ];
    xdg.configFile."native-packages/manifest.json".text = builtins.toJSON manifest;
  };
}
