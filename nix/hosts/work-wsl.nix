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
    ];
    secrets = [ "api-keys" ];
    mise.trustedPaths = [ "~/Projects" ];

    apps = {
      # VS Code runs on Windows and connects through its WSL extension.
      disabled = [ "vscode" ];
      bundles = [
        "cli"
        "security"
        "dev"
        "cloud"
      ];
      enabled = [
        "ffmpeg"
        "glow"
        "google-cloud-sdk"
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
