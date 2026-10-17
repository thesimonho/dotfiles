{
  pkgs,
  pkgsUnstable,
  pkgsPinned,
  symlinkConfig,
}:

{
  bundleNames = [
    "cli"
    "desktop"
    "security"
    "fonts"
    "communication"
    "dev"
    "cloud"
  ];

  applications = {
    android-tools = {
      contributions.nativePackages = {
        arch.pacman = [ "android-tools" ];
        darwin.homebrew.casks = [ "android-platform-tools" ];
        fedora.dnf.packages = [ "android-tools" ];
      };
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
    firefox = {
      contributions.nativePackages = {
        arch.pacman = [ "firefox" ];
        darwin.homebrew.casks = [ "firefox" ];
        fedora.dnf.packages = [ "firefox" ];
      };
      bundles = [ ];
    };
    fzf = {
      contributions.programs.fzf.enable = true;
      contributions.xdgConfigFiles."fzf" = symlinkConfig "fzf";
      bundles = [ "cli" ];
    };
    google-chrome = {
      contributions.nativePackages = {
        arch.aur = [ "google-chrome" ];
        darwin.homebrew.casks = [ "google-chrome" ];
        fedora.dnf = {
          packages = [ "google-chrome-stable" ];
          repositories.google-chrome = {
            baseurl = "https://dl.google.com/linux/chrome/rpm/stable/$basearch";
            gpgkey = "https://dl.google.com/linux/linux_signing_key.pub";
          };
        };
      };
      bundles = [ ];
    };
    google-cloud-sdk = {
      contributions.packages = [ pkgs.google-cloud-sdk ];
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
    master-pdf-editor = {
      contributions.packages = [ pkgs.masterpdfeditor4 ];
      bundles = [ ];
    };
    nh = {
      contributions.packages = [ pkgs.nh ];
      bundles = [ "cli" ];
    };
    nix-output-monitor = {
      contributions.packages = [ pkgs.nix-output-monitor ];
      bundles = [ "cli" ];
    };
    nixd = {
      contributions.packages = [ pkgs.nixd ];
      bundles = [ "cli" ];
    };
    nixfmt = {
      contributions.packages = [ pkgs.nixfmt ];
      bundles = [ "cli" ];
    };
    nodejs = {
      contributions.packages = [ pkgs.nodejs_24 ];
      bundles = [ "cli" ];
    };
    onlyoffice = {
      flatpak.id = "org.onlyoffice.desktopeditors";
    };
    partitionmanager = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      requirements.desktops = [ "kde" ];
      contributions.nativePackages = {
        arch.pacman = [ "partitionmanager" ];
        fedora.dnf.packages = [ "kde-partitionmanager" ];
      };
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
    shelly = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [ "arch" ];
      requirements.hasDesktop = true;
      contributions.nativePackages = {
        arch.pacman = [ "shelly" ];
      };
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
      bundles = [ ];
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
      contributions.nativePackages = {
        arch.pacman = [ "vivaldi" ];
        darwin.homebrew.casks = [ "vivaldi" ];
        fedora.dnf = {
          packages = [ "vivaldi-stable" ];
          repositories.vivaldi = {
            baseurl = "https://repo.vivaldi.com/archive/rpm/$basearch";
            gpgkey = "https://repo.vivaldi.com/archive/linux_signing_key.pub";
          };
        };
      };
      bundles = [ "communication" ];
    };
    vscode = {
      contributions.nativePackages = {
        arch.aur = [ "visual-studio-code-bin" ];
        darwin.homebrew.casks = [ "visual-studio-code" ];
        fedora.dnf = {
          packages = [ "code" ];
          repositories.vscode = {
            baseurl = "https://packages.microsoft.com/yumrepos/vscode";
            gpgkey = "https://packages.microsoft.com/keys/microsoft.asc";
          };
        };
      };
      bundles = [ "dev" ];
    };
    # Linux/Wayland-only; opt in via my.apps.enabled.
    wl-clipboard = {
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      contributions.nativePackages = {
        arch.pacman = [ "wl-clipboard" ];
        fedora.dnf.packages = [ "wl-clipboard" ];
      };
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

  support = {
    android-udev = {
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      contributions.nativePackages.arch.pacman = [ "android-udev" ];
      bundles = [ ];
    };
    dolphin-plugins = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      requirements.desktops = [ "kde" ];
      contributions.nativePackages = {
        arch.pacman = [ "dolphin-plugins" ];
        fedora.dnf.packages = [ "dolphin-plugins" ];
      };
    };
    flatpak-kcm = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [ "arch" ];
      requirements.desktops = [ "kde" ];
      contributions.nativePackages = {
        arch.pacman = [ "flatpak-kcm" ];
      };
    };
    gnome-keyring = {
      bundles = [ "security" ];
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      requirements.desktops = [ "none" ];
      contributions.nativePackages = {
        arch.pacman = [ "gnome-keyring" ];
        fedora.dnf.packages = [
          "gnome-keyring"
          "gnome-keyring-pam"
        ];
      };
    };
    kde-graphics-meta = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [ "arch" ];
      requirements.desktops = [ "kde" ];
      contributions.nativePackages = {
        arch.pacman = [ "kde-graphics-meta" ];
      };
    };
    kde-system-meta = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [ "arch" ];
      requirements.desktops = [ "kde" ];
      contributions.nativePackages = {
        arch.pacman = [ "kde-system-meta" ];
      };
    };
    kio-gdrive = {
      bundles = [ "desktop" ];
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      requirements.desktops = [ "kde" ];
      contributions.nativePackages = {
        arch.pacman = [ "kio-gdrive" ];
        fedora.dnf.packages = [ "kio-gdrive" ];
      };
    };
    libsecret = {
      bundles = [ "security" ];
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      contributions.nativePackages = {
        arch.pacman = [ "libsecret" ];
        fedora.dnf.packages = [ "libsecret" ];
      };
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
    zenity = {
      bundles = [ "security" ];
      requirements.operatingSystems = [
        "arch"
        "fedora"
      ];
      contributions.nativePackages = {
        arch.pacman = [ "zenity" ];
        fedora.dnf.packages = [ "zenity" ];
      };
    };
  };
}
