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
  codexDesktopLinuxFeatures = [
    "authored-message-visibility"
    "automation-extensions"
    "codex-wrapper-updater"
    "computer-use-linux"
    "directory-only-working-tree-watch"
    "global-dictation"
    "node-repl-reaper"
    "open-target-discovery"
    "persistent-status-panel"
    "pet-overlay"
    "preferred-editor-file-links"
    "remote-control-ui"
    "remote-mobile-control"
    "tray-usage"
  ];
  codexDesktopPackage =
    if builtins.elem system linuxSystems then
      (inputs.codex-desktop-linux.packages.${system}.codex-desktop.override {
        enableComputerUseUi = true;
        linuxFeatureIds = codexDesktopLinuxFeatures;
      })
    else
      null;
in
{
  bundleNames = [
    "cli"
    "agents"
    "skills"
  ];

  entries = {
    claude-code = {
      contributions.packages = [ llmAgents.claude-code ];
      bundles = [ "agents" ];
    };
    claude-desktop = {
      # From claude-desktop-bin (not llm-agents): its build patches the Cowork
      # VM probe to honour CLAUDE_OVMF_CODE_PATH / CLAUDE_VIRTIOFSD_PATH and
      # wires OVMF + virtiofsd from nixpkgs. qemu = null drops the bundled qemu
      # from the closure; the Cowork helper finds qemu-system-x86_64 on the
      # session PATH instead (needs the host qemu package + kvm group).
      contributions.packages =
        if builtins.elem system linuxSystems then
          [
            (inputs.claude-desktop-bin.packages.${system}.claude-desktop.override {
              qemu = null;
            })
          ]
        else
          [ ];
      requirements.systems = linuxSystems;
      bundles = [ "agents" ];
    };
    codex = {
      contributions.packages = [ llmAgents.codex ];
      bundles = [ "agents" ];
    };
    codex-desktop = {
      requirements = {
        systems = linuxSystems;
        hasDesktop = true;
      };
      contributions.programs.codexDesktopLinux = {
        enable = true;
        cliPackage = llmAgents.codex;
        package = codexDesktopPackage;
        remoteControl = {
          enable = false; # turning this on breaks QR code pairing for remote control
          package = llmAgents.codex;
        };
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
    claude-code-acp = {
      contributions.packages = [ llmAgents.claude-agent-acp ];
      bundles = [ "agents" ];
    };
    codex-acp = {
      contributions.packages = [ llmAgents.codex-acp ];
      bundles = [ "agents" ];
    };
    agent-browser = {
      contributions.packages = [ llmAgents.agent-browser ];
      bundles = [ "skills" ];
    };
    herdr = {
      contributions.packages = [ pkgsUnstable.herdr ];
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
}
