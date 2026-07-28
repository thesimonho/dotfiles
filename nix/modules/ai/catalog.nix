{
  inputs,
  pkgsUnstable,
  system,
}:

let
  # https://github.com/numtide/llm-agents.nix
  llmAgents = inputs.llm-agents.packages.${system};
  linuxSystems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  codexDesktopLinuxFeatures = [
    "appshots"
    "codex-wrapper-updater"
    "directory-only-working-tree-watch"
    "global-dictation"
    "mcp-helper-reaper"
    "node-repl-reaper"
    "open-target-discovery"
    "persistent-status-panel"
    "pet-overlay"
    "remote-control-ui"
    "remote-mobile-control"
  ];
  # prevent the reaper scripts from adding their own entries into hooks.json
  codexDesktopPackage =
    if builtins.elem system linuxSystems then
      (inputs.codex-desktop-linux.packages.${system}.codex-desktop.override {
        enableComputerUseUi = true;
        linuxFeatureIds = codexDesktopLinuxFeatures;
      }).overrideAttrs
        (previousAttributes: {
          postFixup = (previousAttributes.postFixup or "") + ''
            reaperHookInstaller="$out/opt/codex-desktop/.codex-linux/mcp-helper-reaper/install-session-hook.sh"
            substituteInPlace "$reaperHookInstaller" \
              --replace-fail '[ "''${CODEX_MCP_HELPER_REAPER_DISABLE_HOOK:-}" = "1" ] && exit 0' 'exit 0'
          '';
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
    rtk = {
      contributions.packages = [ llmAgents.rtk ];
      bundles = [ "skills" ];
    };
    huggingface-hub = {
      contributions.packages = [ pkgsUnstable.python3Packages.huggingface-hub ];
      bundles = [ "cli" ];
    };
    tabby = {
      # Native binary for nvim's Tabby process service; Metal acceleration is
      # the build default on aarch64-darwin (the only darwin platform tabby
      # supports). Linux hosts run Tabby through AI/tabby.yaml instead.
      # Sourced from the dedicated nixpkgs-tabby input; see the flake input
      # comment for why newer channels cannot build it.
      # lowPrio: tabby bundles bin/llama-server, which collides with llama.nix's
      # llama-cpp in the profile. tabby spawns the llama-server adjacent to its
      # invoked path (no PATH lookup), so llama.nix's copy serves both.
      contributions.packages = [
        (inputs.nixpkgs.lib.lowPrio inputs.nixpkgs-tabby.legacyPackages.${system}.tabby)
      ];
      requirements.systems = [ "aarch64-darwin" ];
      bundles = [ "cli" ];
    };
  };
}
