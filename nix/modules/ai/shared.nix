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
    installed skill directory under the given target (e.g. ".codex/skills").
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

  home.file = {
    ".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink generatedAgentsPath;
      force = true;
    };
    ".codex/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/config.toml";
      force = true;
    };
    ".codex/hooks.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/hooks.json";
      force = true;
    };
    ".pi/agent/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink generatedAgentsPath;
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
  // mkStaticSkillsFor ".codex/skills"
  // mkStaticSkillsFor ".pi/agent/skills";

  home.activation.generateAgentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export AGENTS_ROOT="${dotfiles}/AI/agents"
    export AWK_BIN="${pkgs.gawk}/bin/awk"
    for target in "$HOME/.codex/skills" "$HOME/.pi/agent/skills"; do
      export SKILLS_OUTPUT="$target"
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${../../../AI/scripts/conversion/build-agent-skills.sh}
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${../../../AI/scripts/conversion/rewrite-agent-frontmatter.sh}
    done
  '';
}
