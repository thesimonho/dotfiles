{ lib }:

let
  inherit (lib) types mkOption;
in
{
  /*
    Build a typed catalog: an `attrsOf submodule` whose entries each carry a
    common shape (package, bundles, sessionVariables, files, services,
    activation) plus per-domain extras.

    Args:
      bundleNames: list of allowed bundle tag strings (enum-enforced).
      extraOptions: attrset of additional submodule options merged into each
                    catalog entry — e.g. `flatpak`, `program`, `needsGpu`.
  */
  mkCatalogType =
    {
      bundleNames,
      extraOptions ? { },
    }:
    types.attrsOf (
      types.submodule {
        options = {
          package = mkOption {
            type = types.nullOr types.package;
            default = null;
            description = "Optional nix package to install for this catalog entry.";
          };
          bundles = mkOption {
            type = types.listOf (types.enum bundleNames);
            default = [ ];
            description = "Bundle tags. Hosts that enable a bundle pull every entry tagged with it.";
          };
          sessionVariables = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Environment variables added when this entry is enabled.";
          };
          files = mkOption {
            type = types.attrs;
            default = { };
            description = "home.file entries merged when this entry is enabled.";
          };
          services = mkOption {
            type = types.attrs;
            default = { };
            description = "systemd.user.services entries merged when this entry is enabled.";
          };
          activation = mkOption {
            type = types.attrs;
            default = { };
            description = "home.activation entries merged when this entry is enabled.";
          };
        }
        // extraOptions;
      }
    );

  /*
    Resolve the set of catalog entry names a host wants:
    union of (entries tagged in any enabled bundle) and individually enabled.
  */
  resolveEnabled =
    {
      catalog,
      bundles,
      enabled,
    }:
    let
      taggedNames = lib.filter (name: lib.any (b: lib.elem b catalog.${name}.bundles) bundles) (
        lib.attrNames catalog
      );
    in
    lib.unique (taggedNames ++ enabled);
}
