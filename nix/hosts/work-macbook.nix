{
  my = {
    os = "darwin";
    desktop = "none";
    gpu.backend = "metal";
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
        "fonts"
        "communication"
        "dev"
        "cloud"
      ];
      enabled = [
        "slack-darwin"
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
    username = "simon.ho";
    homeDirectory = "/Users/simon.ho";
    sessionPath = [ "/usr/local/bin" ];
  };
}
