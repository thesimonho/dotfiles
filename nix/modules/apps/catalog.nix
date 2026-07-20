{
  pkgs,
  pkgsUnstable,
  pkgsPinned,
  symlinkConfig,
}:

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
      contributions.packages = [ pkgs.android-tools ];
      bundles = [ ];
    };
    ast-grep = {
      contributions.packages = [ pkgs.ast-grep ];
      bundles = [ "dev" ];
    };
    awscli2 = {
      contributions.packages = [ pkgs.awscli2 ];
      bundles = [
        "dev"
        "cloud"
      ];
    };
    bat = {
      contributions.programs.bat.enable = true;
      bundles = [ "cli" ];
    };
    betterbird = {
      flatpak = {
        id = "eu.betterbird.Betterbird";
        overrides.Context = {
          filesystems = [
            "xdg-documents:ro"
            "xdg-download"
            "xdg-desktop:ro"
            "xdg-pictures:ro"
            "xdg-videos:ro"
            "xdg-run/gnupg"
            "~/.gnupg"
          ];
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
      contributions.programs.carapace.enable = true;
      bundles = [ "cli" ];
    };
    deskflow = {
      flatpak.id = "org.deskflow.deskflow";
      bundles = [ ];
    };
    devcontainer = {
      contributions.packages = [ pkgs.devcontainer ];
      bundles = [ ];
    };
    discord = {
      flatpak = {
        id = "com.discordapp.Discord";
        overrides.Context.filesystems = [
          "home:ro"
          "xdg-documents:ro"
          "xdg-download"
          "xdg-desktop"
          "xdg-pictures:ro"
          "xdg-videos:ro"
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
      contributions.programs.eza = {
        enable = true;
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
      bundles = [ "cli" ];
    };
    fd = {
      contributions.programs.fd.enable = true;
      bundles = [ "cli" ];
    };
    ffmpeg = {
      contributions.packages = [
        ((pkgsPinned.ffmpeg-full.override { withUnfree = true; }).overrideAttrs (_: {
          doCheck = false;
        }))
      ];
      bundles = [ ];
    };
    fzf = {
      contributions.programs.fzf.enable = true;
      contributions.xdgConfigFiles."fzf" = symlinkConfig "fzf";
      bundles = [ "cli" ];
    };
    gearlever = {
      flatpak.id = "it.mijorus.gearlever";
      bundles = [ ];
    };
    gh = {
      contributions.packages = [ pkgs.gh ];
      bundles = [ "dev" ];
    };
    gitleaks = {
      contributions.packages = [ pkgs.gitleaks ];
      bundles = [
        "security"
        "dev"
      ];
    };
    glow = {
      contributions.packages = [ pkgs.glow ];
      bundles = [ ];
    };
    graphviz = {
      contributions.packages = [ pkgs.graphviz ];
      bundles = [ "cli" ];
    };
    gron = {
      contributions.packages = [ pkgs.gron ];
      bundles = [
        "cli"
      ];
    };
    jq = {
      contributions.packages = [ pkgs.jq ];
      bundles = [
        "cli"
      ];
    };
    just = {
      contributions.packages = [ pkgs.just ];
      bundles = [
        "cli"
        "dev"
      ];
    };
    lazydocker = {
      contributions.packages = [ pkgs.lazydocker ];
      bundles = [
        "cli"
        "dev"
      ];
    };
    lazygit = {
      contributions.packages = [ pkgs.lazygit ];
      contributions.xdgConfigFiles."lazygit" = symlinkConfig "lazygit";
      bundles = [
        "cli"
        "dev"
      ];
    };
    lazyjournal = {
      contributions.packages = [ pkgs.lazyjournal ];
      bundles = [ "cli" ];
    };
    nh = {
      contributions.packages = [ pkgs.nh ];
      bundles = [ "cli" ];
    };
    nix-output-monitor = {
      contributions.packages = [ pkgs.nix-output-monitor ];
      bundles = [ "cli" ];
    };
    nerd-fonts-caskaydia-cove = {
      contributions.packages = [ pkgs.nerd-fonts.caskaydia-cove ];
      bundles = [ "fonts" ];
    };
    nerd-fonts-fira-code = {
      contributions.packages = [ pkgs.nerd-fonts.fira-code ];
      bundles = [ "fonts" ];
    };
    nerd-fonts-jetbrains-mono = {
      contributions.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      bundles = [ "fonts" ];
    };
    nerd-fonts-symbols-only = {
      contributions.packages = [ pkgs.nerd-fonts.symbols-only ];
      bundles = [ "fonts" ];
    };
    nixd = {
      contributions.packages = [ pkgs.nixd ];
      bundles = [ "cli" ];
    };
    nixfmt = {
      contributions.packages = [ pkgs.nixfmt-rfc-style ];
      bundles = [ "cli" ];
    };
    nodejs = {
      contributions.packages = [ pkgs.nodejs_24 ];
      bundles = [ "cli" ];
    };
    onlyoffice = {
      flatpak.id = "org.onlyoffice.desktopeditors";
    };
    pay-respects = {
      contributions.packages = [ pkgs.pay-respects ];
      bundles = [ "cli" ];
    };
    ripgrep = {
      contributions.programs.ripgrep.enable = true;
      bundles = [ "cli" ];
    };
    semgrep = {
      contributions.packages = [ pkgs.semgrep ];
      bundles = [
        "security"
        "dev"
      ];
    };
    slack = {
      flatpak = {
        id = "com.slack.Slack";
        overrides.Context.filesystems = [
          "home:ro"
          "xdg-documents:ro"
          "xdg-download"
          "xdg-desktop"
          "xdg-pictures:ro"
          "xdg-videos:ro"
        ];
      };
      bundles = [ "communication" ];
    };
    # darwin-only; opt in via my.apps.enabled.
    slack-darwin = {
      contributions.packages = [ pkgs.slack ];
      bundles = [ ];
    };
    starship = {
      contributions.programs.starship.enable = true;
      contributions.xdgConfigFiles."starship.toml" = symlinkConfig "starship.toml";
      bundles = [ "cli" ];
    };
    stripe-cli = {
      contributions.packages = [ pkgs.stripe-cli ];
      bundles = [ "dev" ];
    };
    tealdeer = {
      contributions.programs.tealdeer.enable = true;
      bundles = [ "cli" ];
    };
    terraform = {
      bundles = [ "cloud" ];
      contributions.shellAliases.tf = "terraform";
    };
    trivy = {
      contributions.packages = [ pkgs.trivy ];
      bundles = [
        "security"
        "dev"
      ];
    };
    trufflehog = {
      contributions.packages = [ pkgs.trufflehog ];
      bundles = [
        "security"
        "dev"
      ];
    };
    uv = {
      contributions.packages = [ pkgs.uv ];
      bundles = [
        "cli"
        "dev"
      ];
    };
    vivaldi = {
      flatpak.id = "com.vivaldi.Vivaldi";
      bundles = [ "communication" ];
    };
    vscode = {
      flatpak.id = "com.visualstudio.code";
      bundles = [ "dev" ];
    };
    # Linux/Wayland-only; opt in via my.apps.enabled.
    wl-clipboard = {
      contributions.packages = [ pkgs.wl-clipboard ];
      bundles = [ ];
    };
    yq = {
      contributions.packages = [ pkgs.yq ];
      bundles = [
        "cli"
      ];
    };
    zed = {
      flatpak.id = "dev.zed.Zed";
      bundles = [ "dev" ];
    };
    zoxide = {
      contributions.programs.zoxide.enable = true;
      bundles = [ "cli" ];
    };
  };
}
