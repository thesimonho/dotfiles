{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

let
  inherit (lib) mkOption types mkIf;

  catalogLib = import ../lib/catalog.nix { inherit lib; };

  bundleNames = [
    "baseline"
    "security-tools"
    "fonts"
    "communication"
    "desktop"
    "mobile-dev"
    "creative"
    "cloud"
    "gaming"
    "linux-utils"
  ];

  flatpakOverrideType = types.submodule {
    options = {
      id = mkOption {
        type = types.str;
        description = "Flatpak app id (e.g. com.discordapp.Discord).";
      };
      overrides = mkOption {
        type = types.attrs;
        default = { };
        description = "Per-app override block passed to services.flatpak.overrides.";
      };
    };
  };

  programType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "home-manager program key (programs.<name>.enable = true).";
      };
      settings = mkOption {
        type = types.attrs;
        default = { };
        description = "Extra options merged into programs.<name>.";
      };
    };
  };

  appType = catalogLib.mkCatalogType {
    inherit bundleNames;
    extraOptions = {
      flatpak = mkOption {
        type = types.nullOr flatpakOverrideType;
        default = null;
      };
      program = mkOption {
        type = types.nullOr programType;
        default = null;
      };
    };
  };

  ffmpegFull = (pkgs.ffmpeg-full.override { withUnfree = true; }).overrideAttrs (_: {
    doCheck = false;
  });

  /*
    The full app catalog. Each entry is a typed app spec; the dispatcher
    below turns enabled entries into home.packages, services.flatpak.*, and
    programs.* config. Add new tools here, not in hosts.
  */
  catalog = {
    bat = {
      program = {
        name = "bat";
      };
      bundles = [ "baseline" ];
    };
    carapace = {
      program = {
        name = "carapace";
      };
      bundles = [ "baseline" ];
    };
    eza = {
      program = {
        name = "eza";
        settings = {
          colors = "always";
          icons = "always";
          extraOptions = [
            "--hyperlink"
            "--group-directories-first"
            "--header"
          ];
          theme = {
            filekinds.symlink.is_italic = true;
            symlink_path.is_italic = true;
            broken_symlink_path.is_italic = true;
            broken_path_overlay.is_italic = true;
          };
        };
      };
      bundles = [ "baseline" ];
    };
    fd = {
      program = {
        name = "fd";
      };
      bundles = [ "baseline" ];
    };
    fzf = {
      program = {
        name = "fzf";
      };
      bundles = [ "baseline" ];
    };
    ripgrep = {
      program = {
        name = "ripgrep";
      };
      bundles = [ "baseline" ];
    };
    starship = {
      program = {
        name = "starship";
      };
      bundles = [ "baseline" ];
    };
    tealdeer = {
      program = {
        name = "tealdeer";
      };
      bundles = [ "baseline" ];
    };
    zoxide = {
      program = {
        name = "zoxide";
      };
      bundles = [ "baseline" ];
    };

    ast-grep = {
      package = pkgs.ast-grep;
      bundles = [ "baseline" ];
    };
    devcontainer = {
      package = pkgs.devcontainer;
      bundles = [ "baseline" ];
    };
    gh = {
      package = pkgs.gh;
      bundles = [ "baseline" ];
    };
    glow = {
      package = pkgs.glow;
      bundles = [ "baseline" ];
    };
    just = {
      package = pkgs.just;
      bundles = [ "baseline" ];
    };
    lazydocker = {
      package = pkgs.lazydocker;
      bundles = [ "baseline" ];
    };
    lazygit = {
      package = pkgs.lazygit;
      bundles = [ "baseline" ];
    };
    lazyjournal = {
      package = pkgs.lazyjournal;
      bundles = [ "baseline" ];
    };
    nixd = {
      package = pkgs.nixd;
      bundles = [ "baseline" ];
    };
    nixfmt = {
      package = pkgs.nixfmt-rfc-style;
      bundles = [ "baseline" ];
    };
    pay-respects = {
      package = pkgs.pay-respects;
      bundles = [ "baseline" ];
    };
    uv = {
      package = pkgs.uv;
      bundles = [ "baseline" ];
    };
    wl-clipboard = {
      package = pkgs.wl-clipboard;
      bundles = [ "linux-utils" ];
    };

    semgrep = {
      package = pkgs.semgrep;
      bundles = [ "security-tools" ];
    };
    trivy = {
      package = pkgs.trivy;
      bundles = [ "security-tools" ];
    };
    trufflehog = {
      package = pkgs.trufflehog;
      bundles = [ "security-tools" ];
    };

    nerd-fonts-caskaydia-cove = {
      package = pkgs.nerd-fonts.caskaydia-cove;
      bundles = [ "fonts" ];
    };
    nerd-fonts-fira-code = {
      package = pkgs.nerd-fonts.fira-code;
      bundles = [ "fonts" ];
    };
    nerd-fonts-jetbrains-mono = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      bundles = [ "fonts" ];
    };
    nerd-fonts-symbols-only = {
      package = pkgs.nerd-fonts.symbols-only;
      bundles = [ "fonts" ];
    };

    ffmpeg-full = {
      package = ffmpegFull;
      bundles = [ "creative" ];
    };

    bitwarden = {
      flatpak.id = "com.bitwarden.desktop";
      bundles = [ "communication" ];
    };
    discord = {
      flatpak = {
        id = "com.discordapp.Discord";
        overrides.Context.filesystems = [
          "xdg-documents"
          "xdg-download"
          "xdg-pictures"
          "xdg-videos"
        ];
      };
      bundles = [ "communication" ];
    };
    betterbird = {
      flatpak = {
        id = "eu.betterbird.Betterbird";
        overrides.Context = {
          filesystems = [ "~/.gnupg:ro" ];
          sockets = [ "gpg-agent" ];
        };
      };
      bundles = [ "communication" ];
    };
    dropbox = {
      flatpak.id = "com.dropbox.Client";
      bundles = [ "communication" ];
    };
    slack-flatpak = {
      flatpak = {
        id = "com.slack.Slack";
        overrides.Context.filesystems = [
          "xdg-documents"
          "xdg-download"
          "xdg-pictures"
          "xdg-videos"
        ];
      };
      bundles = [ "communication" ];
    };
    deskflow = {
      flatpak.id = "org.deskflow.deskflow";
      bundles = [ "communication" ];
    };

    distroshelf = {
      flatpak.id = "com.ranfdev.DistroShelf";
      bundles = [ "desktop" ];
    };
    gearlever = {
      flatpak.id = "it.mijorus.gearlever";
      bundles = [ "desktop" ];
    };
    vscode-flatpak = {
      flatpak.id = "com.visualstudio.code";
      bundles = [ "desktop" ];
    };

    android-tools = {
      package = pkgs.android-tools;
      bundles = [ "mobile-dev" ];
    };

    awscli2 = {
      package = pkgs.awscli2;
      bundles = [ "cloud" ];
    };
    stripe-cli = {
      package = pkgs.stripe-cli;
      bundles = [ "cloud" ];
    };

    # darwin-only; opt in via my.apps.enabled.
    slack-darwin = {
      package = pkgs.slack;
      bundles = [ ];
    };

    terraform = {
      bundles = [ "cloud" ];
      shellAliases.tf = "terraform";
    };
  };

  resolvedCatalog = config.my.apps.catalog;

  enabledNames = catalogLib.resolveEnabled {
    catalog = resolvedCatalog;
    bundles = config.my.apps.bundles;
    enabled = config.my.apps.enabled;
  };
  enabledEntries = lib.filterAttrs (n: _: lib.elem n enabledNames) resolvedCatalog;

  packageEntries = lib.filterAttrs (_: e: e.package != null) enabledEntries;
  flatpakEntries = lib.filterAttrs (_: e: e.flatpak != null) enabledEntries;
  programEntries = lib.filterAttrs (_: e: e.program != null) enabledEntries;

  hasAnyFlatpak = flatpakEntries != { };
  isLinux = config.my.os != "darwin";

  programsConfig = lib.listToAttrs (
    lib.mapAttrsToList (_: e: {
      name = e.program.name;
      value = {
        enable = true;
      }
      // e.program.settings;
    }) programEntries
  );

  flatpakIds = lib.mapAttrsToList (_: e: e.flatpak.id) flatpakEntries;
  flatpakOverrides = lib.listToAttrs (
    lib.concatMap (
      e:
      lib.optional (e.flatpak.overrides != { }) {
        name = e.flatpak.id;
        value = e.flatpak.overrides;
      }
    ) (lib.attrValues flatpakEntries)
  );

  mergedShellAliases = lib.foldl' (acc: e: acc // e.shellAliases) { } (lib.attrValues enabledEntries);
in
{
  options.my.apps = {
    bundles = mkOption {
      type = types.listOf (types.enum bundleNames);
      default = [ ];
      description = "App bundles enabled on this host.";
    };
    enabled = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Individually enabled catalog entries (in addition to bundles).";
    };
    catalog = mkOption {
      type = appType;
      default = catalog;
      internal = true;
      description = "Internal: the resolved app catalog.";
    };
  };

  config = {
    assertions = lib.mapAttrsToList (name: e: {
      assertion = e.package != null || e.flatpak != null || e.program != null || e.shellAliases != { };
      message = "App catalog entry '${name}' must contribute at least one of package / flatpak / program / shellAliases.";
    }) resolvedCatalog;

    home.packages = lib.mapAttrsToList (_: e: e.package) packageEntries;

    programs = programsConfig // {
      zsh.shellAliases = mergedShellAliases;
    };

    services.flatpak = mkIf (isLinux && hasAnyFlatpak) {
      enable = true;
      uninstallUnmanaged = true;
      remotes = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      update = {
        onActivation = true;
        auto = {
          enable = true;
          onCalendar = "weekly";
        };
      };
      packages = flatpakIds;
      overrides = flatpakOverrides;
    };

    xdg.systemDirs.data = mkIf (isLinux && hasAnyFlatpak) [
      "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
    ];

    xdg.configFile."environment.d/20-flatpak.conf" = mkIf (isLinux && hasAnyFlatpak) {
      text = "XDG_DATA_DIRS=$XDG_DATA_DIRS:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
    };
  };
}
