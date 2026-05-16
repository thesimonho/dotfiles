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

  agentSourcesPath = "${dotfiles}/AI/agents";
  generatedAgentOutputsPath = "${agentSourcesPath}/.generated";
  generateAgentCliConfigs = pkgs.writeShellScript "generate-agent-cli-configs" ''
    export AGENTS_SOURCE_DIR="${agentSourcesPath}"
    export AGENTS_OUTPUT_DIR="${generatedAgentOutputsPath}"
    export SHARED_SKILLS_DIR="$HOME/.agents/skills"
    export YQ_BIN="${pkgs.yq}/bin/yq"
    ${pkgs.nodejs}/bin/node ${dotfiles}/AI/lib/agents/generate-agent-configs.js
  '';

  staticSkillsPath = ../../../AI/skills;
  externalSkillsPath = ../../../AI/skills/.agents/skills;

  directoryNamesFor =
    directory:
    let
      entries = builtins.readDir directory;
    in
    builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries);

  customSkillNames = builtins.filter (name: name != ".agents") (directoryNamesFor staticSkillsPath);
  externalSkillNames =
    if builtins.pathExists externalSkillsPath then directoryNamesFor externalSkillsPath else [ ];

  skillSources =
    map (skillName: {
      name = skillName;
      source = "${dotfiles}/AI/skills/${skillName}";
    }) customSkillNames
    ++ map (skillName: {
      name = skillName;
      source = "${dotfiles}/AI/skills/.agents/skills/${skillName}";
    }) externalSkillNames;

  /*
    Build a `home.file` attrset that symlinks every custom and externally
    installed skill directory under the given target (e.g. ".agents/skills").
  */
  mkStaticSkillsFor =
    targetDir:
    builtins.listToAttrs (
      map (skill: {
        name = "${targetDir}/${skill.name}";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink skill.source;
          force = true;
        };
      }) skillSources
    );
in
lib.mkIf (config.my.ai.bundles != [ ]) {
  home.activation.generateAgentsMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${generateAgentsMd}
  '';

  home.activation.generateAgentCliConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${generateAgentCliConfigs}
  '';

  home.file = {
    ".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink generatedAgentsPath;
      force = true;
    };
    ".codex/agents" = {
      source = config.lib.file.mkOutOfStoreSymlink "${generatedAgentOutputsPath}/codex";
      force = true;
    };
    ".codex/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/config.toml";
      force = true;
    };
    /*
      TODO: Codex writes hook trust decisions into ~/.codex/config.toml as
            [hooks.state]. Since this repo is public and config.toml is tracked,
            do not install hooks.json by default: enabling it forces either
            repeated local trust prompts or committing machine-local approval state.
            Revisit when Codex separates hook trust state from user config.
    */
    # ".codex/hooks.json" = {
    #   source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/hooks.json";
    #   force = true;
    # };
    ".pi/agent/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink generatedAgentsPath;
      force = true;
    };
    ".pi/agent/agents" = {
      source = config.lib.file.mkOutOfStoreSymlink "${generatedAgentOutputsPath}/pi";
      force = true;
    };
    ".pi/agent/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/pi/settings.json";
      force = true;
    };
    ".pi/agent/models.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/pi/models.json";
      force = true;
    };
  }
  // mkStaticSkillsFor "${config.my.ai.claude.targetDir}/skills"
  // mkStaticSkillsFor ".agents/skills";
}
