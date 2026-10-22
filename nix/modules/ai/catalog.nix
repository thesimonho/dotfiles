{
  inputs,
  pkgsUnstable,
  pkgs ? pkgsUnstable,
  system,
  symlinkConfig,
}:

let
  # https://github.com/numtide/llm-agents.nix
  llmAgents = inputs.llm-agents.packages.${system};
  linuxSystems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  codexFeatureConfig = pkgs.writeText "codex-features.json" (
    builtins.toJSON {
      enabled = [
        "automation-extensions"
        "computer-use-linux"
        "directory-only-working-tree-watch"
        "filesystem-root-follow-ups"
        "global-dictation"
        "node-repl-reaper"
        "persistent-status-panel"
        "pet-overlay"
        "preferred-editor-file-links"
        "project-group-last-updated-sort"
        "project-task-sort"
        "remote-control-ui"
        "remote-mobile-control"
        "tray-usage"
        "wayland-global-shortcuts"
      ];
    }
  );
  codexNativeBuild = pkgs.writeShellScript "codex-desktop-native-build" ''
    export CODEX_LINUX_FEATURES_CONFIG=${codexFeatureConfig}
    exec ${pkgs.python3}/bin/python3 ${./scripts/build-codex-desktop.py} "$@"
  '';
in
{
  bundleNames = [
    "cli"
    "agents"
    "skills"
  ];

  applications = {
    claude-code = {
      contributions.packages = [ llmAgents.claude-code ];
      bundles = [ "agents" ];
    };
    claude-desktop = {
      # CachyOS supplies the native Cowork VM dependencies and firmware paths.
      contributions.nativePackages = {
        arch.pacman = [ "claude-desktop" ];
        darwin.homebrew.casks = [ "claude" ];
      };
      requirements = {
        systems = linuxSystems ++ [ "aarch64-darwin" ];
        hasDesktop = true;
      };
      bundles = [ "agents" ];
    };
    codex = {
      contributions.packages = [ llmAgents.codex ];
      bundles = [ "agents" ];
    };
    chatgpt = {
      contributions.nativePackages = {
        arch.aur = [ "codex-desktop-git" ];
        arch.aurBuilds.codex-desktop-git = "${codexNativeBuild}";
        darwin.homebrew.casks = [ "chatgpt" ];
      };
      requirements = {
        systems = linuxSystems ++ [ "aarch64-darwin" ];
        hasDesktop = true;
      };
      bundles = [ "agents" ];
    };
    pi = {
      contributions.packages = [ llmAgents.pi ];
      bundles = [ "agents" ];
    };
    opencode = {
      contributions.packages = [ llmAgents.opencode ];
      bundles = [ "agents" ];
    };
    agent-browser = {
      contributions.packages = [ llmAgents.agent-browser ];
      bundles = [ "skills" ];
    };
    herdr = {
      contributions.packages = [ llmAgents.herdr ];
      contributions.xdgConfigFiles."herdr" = symlinkConfig "herdr";
      bundles = [
        "cli"
        "agents"
      ];
    };
    rtk = {
      contributions.packages = [ llmAgents.rtk ];
      bundles = [ "skills" ];
    };
    huggingface-hub = {
      contributions.packages = [ pkgsUnstable.python3Packages.huggingface-hub ];
      bundles = [ "cli" ];
    };
  };

  support = {
    claude-code-acp = {
      contributions.packages = [ llmAgents.claude-agent-acp ];
      bundles = [ "agents" ];
    };
    codex-acp = {
      contributions.packages = [ llmAgents.codex-acp ];
      bundles = [ "agents" ];
    };
  };
}
