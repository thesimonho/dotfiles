{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  meta = import ../secrets/meta.nix;
in
{
  /*
    System-level identity options: who/where this host is.
    These options are pure declarations — modules elsewhere read them to gate
    behavior. `my.os` is the only required field; everything else has a
    neutral default ("none" / empty) so a host that sets nothing gets nothing.
  */
  options.my = {
    os = mkOption {
      type = types.enum [
        "arch"
        "darwin"
        "fedora"
      ];
      description = "Host operating system. Drives package-manager and DE assumptions.";
    };

    desktop = mkOption {
      type = types.enum [
        "kde"
        "none"
      ];
      default = "none";
      description = "Desktop environment. Darwin hosts always set this to \"none\".";
    };

    gpu.backend = mkOption {
      type = types.enum [
        "none"
        "cuda"
        "rocm"
        "vulkan"
        "metal"
      ];
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
      description = "Identity names from secrets/meta.nix to materialize on this host.";
    };

    secrets = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Non-identity secret names from secrets/meta.nix to decrypt on this host.";
    };

    browser.executable = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "google-chrome-stable";
      description = "Default browser binary, set as CHROME_EXECUTABLE.";
    };

    # Internal: identities/secrets resolved against meta.nix. Modules read
    # these instead of refiltering meta.identities themselves.
    _identities = mkOption {
      type = types.attrs;
      internal = true;
      readOnly = true;
      default = lib.filterAttrs (name: _: lib.elem name config.my.identities) meta.identities;
    };
    _secrets = mkOption {
      type = types.attrs;
      internal = true;
      readOnly = true;
      default = lib.filterAttrs (name: _: lib.elem name config.my.secrets) meta.secrets;
    };
  };
}
