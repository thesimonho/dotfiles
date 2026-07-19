{
  config,
  pkgs,
  pkgsUnstable,
  inputs,
  lib,
  ...
}:

let
  inherit (lib) mkOption types;
  system = pkgs.stdenv.hostPlatform.system;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  codexCliPackage = inputs.llm-agents.packages.${system}.codex;

  catalogData = import ./catalog.nix {
    inherit
      inputs
      isLinux
      pkgsUnstable
      system
      ;
  };
  inherit (catalogData) bundleNames;
  catalog = catalogData.entries;

  catalogLib = import ../../lib/catalog.nix { inherit lib; };

  enabledNames = catalogLib.resolveEnabled {
    inherit catalog;
    bundles = config.my.ai.bundles;
    enabled = config.my.ai.enabled;
  };
  enabledEntries = lib.filterAttrs (n: _: lib.elem n enabledNames) catalog;
  hasDesktop = config.my.desktop != "none";
  isCodexDesktopEnabled = isLinux && hasDesktop && lib.elem "codex-desktop" enabledNames;
in
{
  imports = [
    ./instructions.nix
    ./agents.nix
    ./skills.nix
    ./clients.nix
    ./llama.nix
  ];

  options.my.ai = {
    bundles = mkOption {
      type = types.listOf (types.enum bundleNames);
      default = [ ];
      description = "AI bundles to enable on this host (agents / cli / etc.)";
    };
    enabled = mkOption {
      type = types.listOf (types.enum (lib.attrNames catalog));
      default = [ ];
      description = "Individually enabled AI catalog entries (in addition to bundles).";
    };
  };

  config = {
    home.packages = lib.mapAttrsToList (_: e: e.package) (
      lib.filterAttrs (_: e: e.package != null) enabledEntries
    );

    programs.codexDesktopLinux = lib.mkIf isCodexDesktopEnabled {
      enable = true;
      cliPackage = codexCliPackage;
      computerUseUi.enable = true;
      remoteControl = {
        enable = true;
        package = codexCliPackage;
      };
      linuxFeatures = [
        "appshots"
        "codex-wrapper-updater"
        "directory-only-working-tree-watch"
        "global-dictation"
        "mcp-helper-reaper"
        "node-repl-reaper"
        "open-target-discovery"
        "persistent-status-panel"
        "pet-overlay"
        "remote-control-ui"
        "remote-mobile-control"
      ];
    };
  };
}
