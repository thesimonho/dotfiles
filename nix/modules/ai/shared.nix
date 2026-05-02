{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = config.my.dotfilesPath;

  generateAgentsMd = pkgs.writeShellScript "generate-agents-md" ''
    {
      for file in ${dotfiles}/AI/rules/*.md; do
        cat "$file"
        echo ""
      done
    } > ${dotfiles}/AI/AGENTS.generated.md
  '';

  staticSkills = ../../../AI/skills;
  staticSkillDirs = builtins.readDir staticSkills;
  staticSkillNames = builtins.filter (name: staticSkillDirs.${name} == "directory") (
    builtins.attrNames staticSkillDirs
  );

  /*
    Build a `home.file` attrset that symlinks every static skill directory
    under the given target (e.g. ".codex/skills" or ".pi/agent/skills").
  */
  mkStaticSkillsFor =
    targetDir:
    builtins.listToAttrs (
      map (skillName: {
        name = "${targetDir}/${skillName}";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills/${skillName}";
          force = true;
        };
      }) staticSkillNames
    );
in
{
  home.activation.generateAgentsMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${generateAgentsMd}
  '';

  home.file = {
    ".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.generated.md";
      force = true;
    };
    ".codex/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/config.toml";
      force = true;
    };
    ".pi/agent/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.generated.md";
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
