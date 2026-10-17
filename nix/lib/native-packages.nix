{ lib }:
let
  inherit (lib) mkOption types;
  names =
    description:
    mkOption {
      type = types.listOf (types.strMatching "[a-zA-Z0-9@_+][a-zA-Z0-9@._+\\-]*");
      default = [ ];
      inherit description;
    };
  mapping =
    options:
    mkOption {
      type = types.nullOr (types.submodule { inherit options; });
      default = null;
    };
  https = types.strMatching "https://[^[:space:]]+";
in
rec {
  hasValues =
    value:
    if builtins.isAttrs value then
      lib.any hasValues (lib.attrValues value)
    else
      value != null && value != [ ];

  mappingType = types.submodule {
    options = {
      arch = mapping {
        pacman = names "Exact Arch repository package names.";
        aur = names "Exact AUR package names.";
      };
      darwin = mapping {
        homebrew = {
          formulae = names "Homebrew core formula names.";
          casks = names "Homebrew cask names.";
        };
      };
      fedora = mapping {
        dnf = {
          packages = (names "Exact RPM package names installed with DNF.") // {
            type = types.listOf (types.strMatching "[a-zA-Z0-9_+][a-zA-Z0-9._+\\-]*");
          };
          repositories = mkOption {
            default = { };
            description = "Package repositories; signatures stay required.";
            type = types.attrsOf (
              types.submodule {
                options = {
                  baseurl = mkOption { type = https; };
                  gpgkey = mkOption { type = https; };
                };
              }
            );
          };
        };
      };
    };
  };
}
