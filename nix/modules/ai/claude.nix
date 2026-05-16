{ config, lib, ... }:

let
  dotfiles = config.my.dotfilesPath;
  targetDir = config.my.ai.claude.targetDir;

  claudeMappings = [
    {
      name = "agents";
      source = "${dotfiles}/AI/agents/.generated/claude";
    }
    {
      name = "rules";
      source = "${dotfiles}/AI/instructions/fragments";
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
