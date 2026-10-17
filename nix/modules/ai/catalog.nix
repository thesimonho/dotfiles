{
  inputs,
  pkgsUnstable,
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
        arch.pacman = [ "chatgpt-desktop-bin" ];
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
