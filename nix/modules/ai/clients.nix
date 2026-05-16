{ config, lib, ... }:

let
  inherit (lib) mkOption types;

  dotfiles = config.my.dotfilesPath;
  generatedAgentsPath = "${dotfiles}/AI/instructions/AGENTS.generated.md";
  generatedAgentOutputsPath = "${dotfiles}/AI/agents/.generated";

  mkSymlink = source: {
    source = config.lib.file.mkOutOfStoreSymlink source;
    force = true;
  };

  clientKinds = {
    claude = client: {
      files = {
        "${client.configDir}/agents" = mkSymlink "${generatedAgentOutputsPath}/claude";
        "${client.configDir}/rules" = mkSymlink "${dotfiles}/AI/instructions/fragments";
        "${client.configDir}/settings.json" = mkSymlink "${dotfiles}/AI/settings/claude/settings.json";
      };
      skillsDir = "${client.configDir}/skills";
    };

    codex = client: {
      files = {
        "${client.configDir}/AGENTS.md" = mkSymlink generatedAgentsPath;
        "${client.configDir}/agents" = mkSymlink "${generatedAgentOutputsPath}/codex";
        "${client.configDir}/config.toml" = mkSymlink "${dotfiles}/AI/settings/codex/config.toml";
        /*
          TODO: Codex writes hook trust decisions into ~/.codex/config.toml as
                [hooks.state]. Since this repo is public and config.toml is tracked,
                do not install hooks.json by default: enabling it forces either
                repeated local trust prompts or committing machine-local approval state.
                Revisit when Codex separates hook trust state from user config.
        */
        # "${client.configDir}/hooks.json" = mkSymlink "${dotfiles}/AI/settings/codex/hooks.json";
      };
      skillsDir = null;
    };

    pi = client: {
      files = {
        "${client.configDir}/agent/AGENTS.md" = mkSymlink generatedAgentsPath;
        "${client.configDir}/agent/agents" = mkSymlink "${generatedAgentOutputsPath}/pi";
        "${client.configDir}/agent/settings.json" = mkSymlink "${dotfiles}/AI/settings/pi/settings.json";
        "${client.configDir}/agent/models.json" = mkSymlink "${dotfiles}/AI/settings/pi/models.json";
      };
      skillsDir = null;
    };
  };

  clientConfigs = lib.mapAttrsToList (
    name: client:
    let
      clientConfig =
        clientKinds.${client.kind} or (throw "Unknown AI client kind `${client.kind}` for `${name}`");
    in
    clientConfig client
  ) config.my.ai.clients;

  clientFiles = lib.foldl' (acc: clientConfig: acc // clientConfig.files) { } clientConfigs;
in
{
  options.my.ai = {
    clients = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            kind = mkOption {
              type = types.enum (builtins.attrNames clientKinds);
              description = "Agent CLI client adapter to use.";
            };
            configDir = mkOption {
              type = types.str;
              description = "Home-relative config directory for this client.";
            };
          };
        }
      );
      default = { };
      description = "Agent CLI clients keyed by local instance name.";
    };

    clientInstallations = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      internal = true;
      description = "Resolved AI client installation metadata shared between AI modules.";
    };
  };

  config = lib.mkIf (config.my.ai.bundles != [ ]) {
    my.ai.clientInstallations = clientConfigs;
    home.file = clientFiles;
  };
}
