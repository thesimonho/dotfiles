{ config, ... }:

{
  my = {
    os = "wsl";
    desktop = "none";
    # Windows account under C:\Users — mirrors WezTerm config to the Windows
    # side. Verify this matches the actual account; a wrong value just no-ops.
    wsl.windowsUser = "simon";
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
