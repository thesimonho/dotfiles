{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  home = {
    packages = with pkgs; [
      pkgsUnstable.claude-code
      pkgsUnstable.claude-code-acp
      pkgsUnstable.codex
      pkgsUnstable.codex-acp
    ];
  };

  # symlinks
  home.file = {
    ".claude/personal/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.md";
      force = true;
    };
    ".claude/personal/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills";
      force = true;
    };
    ".claude/personal/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/claude/settings.json";
      force = true;
    };
    ".claude/work/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.md";
      force = true;
    };
    ".claude/work/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills";
      force = true;
    };
    ".claude/work/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/claude/settings.json";
      force = true;
    };

    ".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.md";
      force = true;
    };
    ".codex/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills";
      force = true;
    };
    ".codex/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/codex/config.toml";
      force = true;
    };
  };
}
