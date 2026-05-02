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
  my = {
    os = lib.mkDefault "darwin";
    desktop = lib.mkDefault "none";
    gpu.backend = lib.mkDefault "metal";
    identities = lib.mkDefault [
      "personal"
      "sprung"
    ];
    secrets = lib.mkDefault [ "api-keys" ];
  };

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
  ai.gpuBackend = lib.mkDefault "metal";
}
