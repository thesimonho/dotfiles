{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  identityRegistry = import ../identities.nix;
  hostContextLib = import ../lib/host-context.nix;
  inherit (hostContextLib) requirementValues;
in
{
  /*
    System-level identity options: who/where this host is.
    These options are pure declarations — modules elsewhere read them to gate
    behavior. `my.os` is the only required field; everything else has a
    neutral default ("none" / empty) so a host that sets nothing gets nothing.
  */
  options.my = {
    hostName = mkOption {
      type = types.str;
      description = "Flake homeConfigurations key for this host (e.g. \"desktop\").";
    };

    os = mkOption {
      type = types.enum requirementValues.operatingSystems;
      description = ''
        Host platform. Drives package-manager and desktop assumptions.
      '';
    };

    desktop = mkOption {
      type = types.enum requirementValues.desktops;
      default = "none";
      description = "Desktop environment. Darwin hosts always set this to \"none\".";
    };

    hasDesktop = mkOption {
      type = types.bool;
      default = config.my.desktop != "none";
      defaultText = lib.literalExpression ''config.my.desktop != "none"'';
      description = "Whether this host has a graphical desktop, independently of its desktop environment.";
    };

    gpu.backend = mkOption {
      type = types.enum requirementValues.gpuBackends;
      default = "none";
      description = "GPU backend used by AI / compute modules.";
    };

    dotfilesPath = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/dotfiles";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/dotfiles"'';
      description = "Where the dotfiles repo is checked out on this host.";
    };

    identities = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "personal"
        "sprung"
      ];
      description = "Identity names from identities.nix to materialize on this host.";
    };

    browser.executable = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "google-chrome-stable";
      description = "Default browser binary, set as CHROME_EXECUTABLE.";
    };

    # Public identity metadata selected for this host.
    _identities = mkOption {
      type = types.attrs;
      internal = true;
      readOnly = true;
      default = lib.filterAttrs (name: _: lib.elem name config.my.identities) identityRegistry.identities;
    };
  };
}
