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
    zsh = {
      shellAliases = {
        tf = "terraform";
      };
    };
  };

  ai.claudeTargetDir = lib.mkDefault ".claude2";
  ai.gpuVendor = lib.mkDefault "none";
}
