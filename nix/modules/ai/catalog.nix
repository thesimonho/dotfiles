{
  inputs,
  pkgsUnstable,
  system,
  isLinux,
}:

let
  # https://github.com/numtide/llm-agents.nix
  llmAgents = inputs.llm-agents.packages.${system};
in
{
  bundleNames = [
    "cli"
    "agents"
    "skills"
  ];

  /*
    Catalog of AI tools shipped as plain packages. Each entry is data only —
    bundles tag the entry; the dispatcher in default.nix turns them into
    home.packages. Tools with non-trivial setup (Claude link tree, llama-cpp
    custom build, llama-swap service) live in sibling module bodies, not here.
  */
  entries = {
    claude-code = {
      package = llmAgents.claude-code;
      bundles = [ "agents" ];
    };
    claude-desktop = {
      # From claude-desktop-bin (not llm-agents): its build patches the Cowork
      # VM probe to honour CLAUDE_OVMF_CODE_PATH / CLAUDE_VIRTIOFSD_PATH and
      # wires OVMF + virtiofsd from nixpkgs. qemu = null drops the bundled qemu
      # from the closure; the Cowork helper finds qemu-system-x86_64 on the
      # session PATH instead (needs the host qemu package + kvm group).
      #
      # Linux-only: the app drives a KVM/QEMU Cowork VM and claude-desktop-bin
      # publishes no Darwin build, so on macOS hosts we set the package to null.
      # The dispatcher (default.nix) filters null packages out, so this drops
      # cleanly instead of throwing on the missing aarch64-darwin attribute.
      package =
        if isLinux then
          inputs.claude-desktop-bin.packages.${system}.claude-desktop.override {
            qemu = null;
          }
        else
          null;
      bundles = [ "agents" ];
    };
    codex = {
      package = llmAgents.codex;
      bundles = [ "agents" ];
    };
    codex-desktop = {
      # The AI dispatcher enables the upstream Home Manager module. Keeping
      # this package null avoids installing the unwrapped desktop package.
      package = null;
      bundles = [ "agents" ];
    };
    pi = {
      package = llmAgents.pi;
      bundles = [ "agents" ];
    };
    opencode = {
      package = llmAgents.opencode;
      bundles = [ "agents" ];
    };
    claude-code-acp = {
      package = llmAgents.claude-agent-acp;
      bundles = [ "agents" ];
    };
    codex-acp = {
      package = llmAgents.codex-acp;
      bundles = [ "agents" ];
    };
    agent-browser = {
      package = llmAgents.agent-browser;
      bundles = [ "skills" ];
    };
    rtk = {
      package = llmAgents.rtk;
      bundles = [ "skills" ];
    };
    huggingface-hub = {
      package = pkgsUnstable.python3Packages.huggingface-hub;
      bundles = [ "cli" ];
    };
  };
}
