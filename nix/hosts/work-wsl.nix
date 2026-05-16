{ config, ... }:

{
  my = {
    os = "wsl";
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
      clients = {
        claude = {
          kind = "claude";
          configDir = ".claude-2";
        };
        codex = {
          kind = "codex";
          configDir = ".codex";
        };
      };
    };
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = { };
  };
}
