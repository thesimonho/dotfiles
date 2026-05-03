{ pkgs, symlinkConfig }:

{
  bundleNames = [
    "cli"
    "security"
    "fonts"
    "communication"
    "dev"
    "cloud"
  ];

  entries = {
    android-tools = {
      package = pkgs.android-tools;
      bundles = [ ];
    };
    ast-grep = {
      package = pkgs.ast-grep;
      bundles = [ "dev" ];
    };
    awscli2 = {
      package = pkgs.awscli2;
      bundles = [
        "dev"
        "cloud"
      ];
    };
    bat = {
      program = {
        name = "bat";
      };
      bundles = [ "cli" ];
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
    bitwarden = {
      flatpak.id = "com.bitwarden.desktop";
      bundles = [ ];
    };
    carapace = {
      program = {
        name = "carapace";
      };
      bundles = [ "cli" ];
    };
    deskflow = {
      flatpak.id = "org.deskflow.deskflow";
      bundles = [ ];
    };
    devcontainer = {
      package = pkgs.devcontainer;
      bundles = [ "dev" ];
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
    distroshelf = {
      flatpak.id = "com.ranfdev.DistroShelf";
      bundles = [ ];
    };
    dropbox = {
      flatpak.id = "com.dropbox.Client";
      bundles = [ ];
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
      bundles = [ "cli" ];
    };
    fd = {
      program = {
        name = "fd";
      };
      bundles = [ "cli" ];
    };
    ffmpeg = {
      package = (pkgs.ffmpeg-full.override { withUnfree = true; }).overrideAttrs (_: {
        doCheck = false;
      });
      bundles = [ ];
    };
    fzf = {
      program = {
        name = "fzf";
      };
      xdgConfigFiles."fzf" = symlinkConfig "fzf";
      bundles = [ "cli" ];
    };
    gearlever = {
      flatpak.id = "it.mijorus.gearlever";
      bundles = [ ];
    };
    gh = {
      package = pkgs.gh;
      bundles = [ "dev" ];
    };
    glow = {
      package = pkgs.glow;
      bundles = [ ];
    };
    just = {
      package = pkgs.just;
      bundles = [
        "cli"
        "dev"
      ];
    };
    lazydocker = {
      package = pkgs.lazydocker;
      bundles = [
        "cli"
        "dev"
      ];
    };
    lazygit = {
      package = pkgs.lazygit;
      xdgConfigFiles."lazygit" = symlinkConfig "lazygit";
      bundles = [
        "cli"
        "dev"
      ];
    };
    lazyjournal = {
      package = pkgs.lazyjournal;
      bundles = [ "cli" ];
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
    nixd = {
      package = pkgs.nixd;
      bundles = [ "cli" ];
    };
    nixfmt = {
      package = pkgs.nixfmt-rfc-style;
      bundles = [ "cli" ];
    };
    pay-respects = {
      package = pkgs.pay-respects;
      bundles = [ "cli" ];
    };
    ripgrep = {
      program = {
        name = "ripgrep";
      };
      bundles = [ "cli" ];
    };
    semgrep = {
      package = pkgs.semgrep;
      bundles = [
        "security"
        "dev"
      ];
    };
    slack = {
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
    # darwin-only; opt in via my.apps.enabled.
    slack-darwin = {
      package = pkgs.slack;
      bundles = [ ];
    };
    starship = {
      program = {
        name = "starship";
      };
      xdgConfigFiles."starship.toml" = symlinkConfig "starship.toml";
      bundles = [ "cli" ];
    };
    stripe-cli = {
      package = pkgs.stripe-cli;
      bundles = [ "dev" ];
    };
    tealdeer = {
      program = {
        name = "tealdeer";
      };
      bundles = [ "cli" ];
    };
    terraform = {
      bundles = [ "cloud" ];
      shellAliases.tf = "terraform";
    };
    trivy = {
      package = pkgs.trivy;
      bundles = [
        "security"
        "dev"
      ];
    };
    trufflehog = {
      package = pkgs.trufflehog;
      bundles = [
        "security"
        "dev"
      ];
    };
    uv = {
      package = pkgs.uv;
      bundles = [
        "cli"
        "dev"
      ];
    };
    vscode = {
      flatpak.id = "com.visualstudio.code";
      bundles = [ "dev" ];
    };
    # Linux/Wayland-only; opt in via my.apps.enabled.
    wl-clipboard = {
      package = pkgs.wl-clipboard;
      bundles = [ ];
    };
    zoxide = {
      program = {
        name = "zoxide";
      };
      bundles = [ "cli" ];
    };
  };
}
