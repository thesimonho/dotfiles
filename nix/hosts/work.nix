{
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  sharedPackages = [
    pkgs.awscli2
  ];
  linuxPackages = lib.optionals isLinux [ ];
  darwinPackages = lib.optionals isDarwin [
    pkgs.slack
  ];
in
{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = {
    username = "simon.ho";
    homeDirectory = "/Users/simon.ho";
    sessionPath = [ "/usr/local/bin" ];
    packages = sharedPackages ++ linuxPackages ++ darwinPackages;
  };

  services.flatpak = lib.mkIf isLinux {
    packages = [ "com.slack.Slack" ];
    overrides = {
      "com.slack.Slack".Context = {
        filesystems = [
          "xdg-documents"
          "xdg-download"
          "xdg-pictures"
          "xdg-videos"
        ];
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    gh = {
      hosts = {
        "github.com" = {
          user = "simon@sprungstudios.com";
        };
      };
    };
    git = {
      settings = {
        user = {
          email = "simon@sprungstudios.com";
        };
        url = {
          "ssh://git@github.com/" = {
            insteadOf = "https://github.com/";
          };
        };
      };
    };
    zsh = {
      shellAliases = {
        tf = "terraform";
      };
    };
  };

  ai.gpuVendor = lib.mkDefault "none";
}
