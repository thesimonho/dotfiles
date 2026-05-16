{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = config.my.dotfilesPath;
  instructionFragmentsPath = "${dotfiles}/AI/instructions/fragments";
  generatedAgentsPath = "${dotfiles}/AI/instructions/AGENTS.generated.md";

  generateAgentsMd = pkgs.writeShellScript "generate-agents-md" ''
    {
      for file in ${instructionFragmentsPath}/*.md; do
        cat "$file"
        echo ""
      done
    } > ${generatedAgentsPath}
  '';
in
lib.mkIf (config.my.ai.bundles != [ ]) {
  home.activation.generateAgentsMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${generateAgentsMd}
  '';
}
