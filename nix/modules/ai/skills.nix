{ config, lib, ... }:

let
  dotfiles = config.my.dotfilesPath;
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

  mkSymlink = source: {
    source = config.lib.file.mkOutOfStoreSymlink source;
    force = true;
  };

  mkStaticSkillsFor =
    clientSkillsDir:
    builtins.listToAttrs (
      map (skill: {
        name = "${clientSkillsDir}/${skill.name}";
        value = mkSymlink skill.source;
      }) skillSources
    );

  clientSkillDirs = [
    ".agents/skills"
  ]
  ++ builtins.filter (clientSkillsDir: clientSkillsDir != null) (
    map (client: client.skillsDir) config.my.ai.clientInstallations
  );

  skillFiles = lib.foldl' (
    acc: clientSkillsDir: acc // mkStaticSkillsFor clientSkillsDir
  ) { } clientSkillDirs;
in
lib.mkIf (config.my.ai.bundles != [ ]) {
  home.file = skillFiles;
}
