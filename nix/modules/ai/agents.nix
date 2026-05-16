{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = config.my.dotfilesPath;
  agentSourcesPath = "${dotfiles}/AI/agents";
  generatedAgentOutputsPath = "${agentSourcesPath}/.generated";

  generateAgentCliConfigs = pkgs.writeShellScript "generate-agent-cli-configs" ''
    export AGENTS_SOURCE_DIR="${agentSourcesPath}"
    export AGENTS_OUTPUT_DIR="${generatedAgentOutputsPath}"
    export SHARED_SKILLS_DIR="$HOME/.agents/skills"
    export YQ_BIN="${pkgs.yq}/bin/yq"
    ${pkgs.nodejs}/bin/node ${dotfiles}/AI/lib/agents/generate-agent-configs.js
  '';
in
lib.mkIf (config.my.ai.bundles != [ ]) {
  home.activation.generateAgentCliConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${generateAgentCliConfigs}
  '';
}
