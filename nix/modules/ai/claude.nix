{ config, lib, ... }:

let
  dotfiles = config.my.dotfilesPath;
  targetDir = config.my.ai.claude.targetDir;

  claudeMappings = [
    {
      name = "agents";
      source = "${dotfiles}/AI/agents";
    }
    {
      name = "hooks";
      source = "${dotfiles}/AI/hooks";
    }
    {
      name = "rules";
      source = "${dotfiles}/AI/rules";
    }
    {
      name = "scripts";
      source = "${dotfiles}/AI/scripts";
    }
    {
      name = "skills";
      source = "${dotfiles}/AI/skills";
    }
    {
      name = "settings.json";
      source = "${dotfiles}/AI/settings/claude/settings.json";
    }
  ];

  claudeLinks = lib.listToAttrs (
    map (item: {
      name = "${targetDir}/${item.name}";
      value = {
        source = config.lib.file.mkOutOfStoreSymlink item.source;
        force = true;
      };
    }) claudeMappings
  );
in
{
  home.file = claudeLinks;
}
