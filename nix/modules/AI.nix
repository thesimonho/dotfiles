{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  gpuVendor = config.ai.gpuVendor;
  ollamaPackage =
    if gpuVendor == "nvidia" then
      if builtins.hasAttr "ollama-cuda" pkgsUnstable then
        pkgsUnstable."ollama-cuda"
      else
        pkgsUnstable.ollama
    else if gpuVendor == "amd" then
      if builtins.hasAttr "ollama-rocm" pkgsUnstable then
        pkgsUnstable."ollama-rocm"
      else
        pkgsUnstable.ollama
    else
      null;

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

  staticSkills = ../../AI/skills;
  staticSkillDirs = builtins.readDir staticSkills;
  staticSkillNames = builtins.filter (name: staticSkillDirs.${name} == "directory") (
    builtins.attrNames staticSkillDirs
  );

  mkCodexStaticSkills = builtins.listToAttrs (
    map (skillName: {
      name = ".codex/skills/${skillName}";
      value = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/AI/skills/${skillName}";
        force = true;
      };
    }) staticSkillNames
  );
in
{
  options.ai.claudeTargetDir = lib.mkOption {
    type = lib.types.str;
    default = ".claude";
    description = "Target directory for Claude symlinks (e.g. .claude or .claude2).";
  };

  options.ai.gpuVendor = lib.mkOption {
    type = lib.types.enum [
      "none"
      "nvidia"
      "amd"
    ];
    default = "none";
    description = "GPU vendor for selecting Ollama package variants.";
  };

  config = {
    home = {
      sessionVariables = {
        CLAUDE_CODE_ENABLE_TELEMETRY = 1;
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317";
        OTEL_EXPORTER_OTLP_HEADERS = "";
      };
      packages = [
        pkgsUnstable.claude-code
        pkgsUnstable.claude-code-acp
        pkgsUnstable.codex
        pkgsUnstable.codex-acp
      ]
      ++ lib.optionals (ollamaPackage != null) [ ollamaPackage ];
    };

    # Generate agents.md file
    home.activation.generateAgentsMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${generateAgentsMd}
    '';

    # symlinks
    home.file =
      {
        ".codex/AGENTS.md" = {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/AGENTS.generated.md";
          force = true;
        };
        ".codex/config.toml" = {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/AI/settings/codex/config.toml";
          force = true;
        };
      }
      // mkClaudeLinks config.ai.claudeTargetDir
      // mkCodexStaticSkills;

    home.activation.generateCodexSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export AGENTS_ROOT="${dotfiles}/AI/agents"
      export SKILLS_OUTPUT="$HOME/.codex/skills"
      export AWK_BIN="${pkgs.gawk}/bin/awk"
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${../../AI/scripts/conversion/build-codex-skills.sh}
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${../../AI/scripts/conversion/rewrite-agent-frontmatter.sh}
    '';
  };
}
