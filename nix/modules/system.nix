{ config, lib, ... }:

let
  inherit (lib) mkOption types;
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

    gpu = {
      backend = mkOption {
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
      cuda.capabilities = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "8.6" ];
        description = "CUDA compute capabilities to compile for. Empty unless backend = cuda.";
      };
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
  };
}
