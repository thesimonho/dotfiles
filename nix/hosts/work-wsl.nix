{ config, ... }:

{
  my = {
    os = "fedora";
    desktop = "none";
    gpu.backend = "cuda";
    identities = [
      "personal"
      "sprung"
    ];
    secrets = [ "api-keys" ];
    mise.trustedPaths = [ "~/Projects" ];

    apps = {
      bundles = [
        "cli"
        "security"
        "dev"
        "cloud"
      ];
      enabled = [
        "ffmpeg"
        "glow"
      ];
    };
    ai = {
      bundles = [
        "agents"
        "cli"
        "skills"
      ];
      claude.targetDir = ".claude2";
    };
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = { };
  };
}
