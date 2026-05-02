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
    apps = {
      bundles = [
        "baseline"
        "security-tools"
        "fonts"
        "cloud"
      ];
      enabled = [ "slack-darwin" ];
    };
    ai = {
      bundles = [
        "cli-agents"
        "tooling"
        "local-models"
      ];
      claude.targetDir = ".claude2";
    };
  };

  home = {
    username = "simon.ho";
    homeDirectory = "/Users/simon.ho";
    sessionPath = [ "/usr/local/bin" ];
  };
}
