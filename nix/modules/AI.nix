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

  claudeMappings = [
    {
      name = "agents";
      source = "${dotfiles}/AI/agents";
    }
    {
      name = "commands";
      source = "${dotfiles}/AI/commands";
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
      name = "statusline";
      source = "${dotfiles}/AI/settings/claude/statusline";
    }
    {
      name = "settings.json";
      source = "${dotfiles}/AI/settings/claude/settings.json";
    }
  ];

  mkClaudeLinks =
    targetDir:
    lib.listToAttrs (
      map (item: {
        name = "${targetDir}/${item.name}";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink item.source;
          force = true;
        };
      }) claudeMappings
    );

  generateAgentsMd = pkgs.writeShellScript "generate-agents-md" ''
    {
      for file in ${dotfiles}/AI/rules/*.md; do
        cat "$file"
        echo ""
      done
    } > ${dotfiles}/AI/AGENTS.generated.md
  '';
in
{
  home = {
    sessionVariables = {
      CLAUDE_PLUGIN_ROOT = "${dotfiles}/AI";
    };
    packages = [
      pkgsUnstable.claude-code
      pkgsUnstable.claude-code-acp
      pkgsUnstable.codex
      pkgsUnstable.codex-acp
    ];
  };

  # Generate agents.md file
  home.activation.generateAgentsMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${generateAgentsMd}
  '';

  # symlinks
  home.file = {
    ".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.generated.md";
      force = true;
    };
    ".codex/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/skills";
      force = true;
    };
    ".codex/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/config.toml";
      force = true;
    };
  }
  // mkClaudeLinks ".claude"
  // mkClaudeLinks ".claude-2";
}
