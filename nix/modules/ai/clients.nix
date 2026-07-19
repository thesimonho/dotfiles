{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  dotfiles = config.my.dotfilesPath;
  generatedAgentsPath = "${dotfiles}/AI/instructions/AGENTS.generated.md";
  generatedAgentOutputsPath = "${dotfiles}/AI/agents/.generated";
  codexManagedConfigPath = "${dotfiles}/AI/settings/codex/config.toml";
  codexConfigMerger = pkgs.writeShellApplication {
    name = "codex-config-merge";
    runtimeInputs = [ (pkgs.python3.withPackages (pythonPackages: [ pythonPackages.tomlkit ])) ];
    text = ''
      exec python ${./scripts/merge-codex-config.py} "$@"
    '';
  };

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

    codex =
      client:
      let
        configApplyPackage = pkgs.writeShellApplication {
          name = "${client.name}-config-apply";
          runtimeInputs = [ codexConfigMerger ];
          text = ''
            codex-config-merge \
              --managed ${lib.escapeShellArg codexManagedConfigPath} \
              --local ${lib.escapeShellArg "${config.home.homeDirectory}/${client.configDir}/config.toml"} \
              --state ${lib.escapeShellArg "${config.xdg.stateHome}/dotfiles/codex/${client.name}-managed-keys.json"}
          '';
        };
      in
      {
        files = {
          "${client.configDir}/AGENTS.md" = mkSymlink generatedAgentsPath;
          "${client.configDir}/agents" = mkSymlink "${generatedAgentOutputsPath}/codex";
          "${client.configDir}/rules" = mkSymlink "${dotfiles}/AI/settings/codex/rules";
          /*
            Hooks remain opt-in. Their trust decisions can safely stay in the
            writable local config without entering the tracked baseline.
          */
          # "${client.configDir}/hooks.json" = mkSymlink "${dotfiles}/AI/settings/codex/hooks.json";
        };
        skillsDir = null;
        packages = [ configApplyPackage ];
        activation = ''
          run ${configApplyPackage}/bin/${client.name}-config-apply
        '';
      };

    pi = client: {
      files = {
        "${client.configDir}/agent/AGENTS.md" = mkSymlink generatedAgentsPath;
        "${client.configDir}/agent/agents" = mkSymlink "${generatedAgentOutputsPath}/pi";
        "${client.configDir}/agent/settings.json" = mkSymlink "${dotfiles}/AI/settings/pi/settings.json";
        "${client.configDir}/agent/models.json" = mkSymlink "${dotfiles}/AI/settings/pi/models.json";
      };
      skillsDir = null;
      packages = [ ];
      activation = "";
    };
  };

  clientConfigs = lib.mapAttrsToList (
    name: client:
    let
      clientConfig =
        clientKinds.${client.kind} or (throw "Unknown AI client kind `${client.kind}` for `${name}`");
    in
    clientConfig (client // { inherit name; })
  ) config.my.ai.clients;

  clientFiles = lib.foldl' (acc: clientConfig: acc // clientConfig.files) { } clientConfigs;
  clientPackages = lib.concatMap (clientConfig: clientConfig.packages or [ ]) clientConfigs;
  clientActivations = lib.concatMap (
    clientConfig: lib.optional ((clientConfig.activation or "") != "") clientConfig.activation
  ) clientConfigs;
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
              description = "Home-relative directory where this client config is installed.";
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
    home.packages = clientPackages;
    home.activation.reconcileCodexConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" clientActivations
    );
  };
}
