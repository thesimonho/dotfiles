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
    ".claude/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.md";
      force = true;
    };
    ".claude/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills";
      force = true;
    };
    ".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/claude/settings.json";
      force = true;
    };

    ".claude-2/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.md";
      force = true;
    };
    ".claude-2/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills";
      force = true;
    };
    ".claude-2/settings.json" = {
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
