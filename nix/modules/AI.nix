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
  llmAgents = inputs.llm-agents.packages.${system};

  # GGUF repos that ship a vision projector (mmproj-F16.gguf).
  # Downloaded idempotently during activation so --mmproj paths in
  # llama-swap.yaml resolve without manual intervention.
  mmprojRepos = [
    "Qwen3.5-9B-GGUF"
    "Qwen3.6-27B-GGUF"
    "Qwen3.6-35B-A3B-GGUF"
  ];

  # Path to host NVIDIA driver lib on non-NixOS (CachyOS, Arch, etc).
  # Used to LD_PRELOAD libcuda.so.1 so the nix-built llama-cpp can find it
  # without polluting LD_LIBRARY_PATH (which would break BLAS linkage).
  hostCudaDriver = "/usr/lib/libcuda.so.1";
  llamaCppPackage =
    if config.ai.gpuBackend == "none" then
      null
    else
      (pkgsUnstable.llama-cpp.override {
        blasSupport = true;
        cudaSupport = config.ai.gpuBackend == "cuda";
        rocmSupport = config.ai.gpuBackend == "rocm";
        vulkanSupport = config.ai.gpuBackend == "vulkan";
        metalSupport = config.ai.gpuBackend == "metal";
      }).overrideAttrs
        (oldAttrs: {
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgsUnstable.makeWrapper ];
          cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [ "-DGGML_NATIVE=ON" ];
          preConfigure = ''
            export NIX_ENFORCE_NO_NATIVE=0
            ${oldAttrs.preConfigure or ""}
          '';
          postFixup =
            (oldAttrs.postFixup or "")
            + lib.optionalString (config.ai.gpuBackend == "cuda") ''
              for bin in $out/bin/*; do
                if [ -f "$bin" ] && [ -x "$bin" ]; then
                  wrapProgram "$bin" --prefix LD_PRELOAD : ${hostCudaDriver}
                fi
              done
            '';
        });

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

  mkStaticSkillsFor =
    targetDir:
    builtins.listToAttrs (
      map (skillName: {
        name = "${targetDir}/${skillName}";
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

  options.ai.gpuBackend = lib.mkOption {
    type = lib.types.enum [
      "none"
      "cuda"
      "rocm"
      "vulkan"
      "metal"
    ];
    default = "none";
    description = "GPU backend for selecting llama-cpp build variant.";
  };

  config = {
    home = {
      sessionVariables = { };
      packages = [
        llmAgents.claude-code
        llmAgents.codex
        llmAgents.pi
        llmAgents.skills
        llmAgents.agent-browser
        llmAgents.rtk
        pkgsUnstable.python3Packages.huggingface-hub
      ]
      ++ lib.optionals (llamaCppPackage != null) [
        llamaCppPackage
        pkgsUnstable.llama-swap
      ];
    };

    systemd.user.services.llama-swap = lib.mkIf (llamaCppPackage != null) {
      Unit = {
        Description = "llama-swap - OpenAI-compatible proxy with model swapping";
        After = [ "network.target" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "simple";
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
        ExecStart = "${pkgsUnstable.llama-swap}/bin/llama-swap --config ${dotfiles}/AI/settings/llama-swap.yaml --listen 127.0.0.1:9292 --watch-config";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Generate agents.md file
    home.activation.generateAgentsMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${generateAgentsMd}
    '';

    # Download mmproj files for vision-capable GGUFs if missing.
    home.activation.downloadMmprojFiles = lib.mkIf (config.ai.gpuBackend != "none") (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        for repo in ${lib.concatStringsSep " " mmprojRepos}; do
          target="$HOME/.cache/llama.cpp/$repo/mmproj-F16.gguf"
          if [ ! -f "$target" ]; then
            echo "==> Downloading mmproj for $repo"
            $DRY_RUN_CMD ${pkgsUnstable.python3Packages.huggingface-hub}/bin/hf download \
              "unsloth/$repo" \
              --include "mmproj-F16.gguf" \
              --local-dir "$HOME/.cache/llama.cpp/$repo" || \
              echo "  WARN: failed to download mmproj for $repo (continuing)"
          fi
        done
      ''
    );

    # symlinks
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
    // mkClaudeLinks config.ai.claudeTargetDir
    // mkStaticSkillsFor ".codex/skills"
    // mkStaticSkillsFor ".pi/agent/skills";

    home.activation.generateAgentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export AGENTS_ROOT="${dotfiles}/AI/agents"
      export AWK_BIN="${pkgs.gawk}/bin/awk"
      for target in "$HOME/.codex/skills" "$HOME/.pi/agent/skills"; do
        export SKILLS_OUTPUT="$target"
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${../../AI/scripts/conversion/build-agent-skills.sh}
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${../../AI/scripts/conversion/rewrite-agent-frontmatter.sh}
      done
    '';
  };
}
