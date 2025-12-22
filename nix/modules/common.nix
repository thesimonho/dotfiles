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
in
{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  imports = [ ./zsh.nix ];
  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.autostart.enable = true;
  xdg.systemDirs.data = [
    "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
    "/var/lib/flatpak/exports/share"
  ];
  xdg.configFile."environment.d/20-flatpak.conf".text = ''
    XDG_DATA_DIRS=$XDG_DATA_DIRS:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share
  '';

  home = {
    sessionVariables = {
      EDITOR = "nvim";
      LANG = "en_US.UTF-8";
      COLORTERM = "truecolor";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    };
    sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];
    shell.enableShellIntegration = true;
    packages = with pkgs; [
      # docker
      eza
      lazydocker
      lazygit
      lazyjournal
      luajitPackages.luarocks_bootstrap
      neovim
      nixd
      nixfmt-rfc-style
      # nerd-fonts.fira-code
      # nerd-fonts.jetbrains-mono
      # nerd-fonts.symbols-only
      nodejs_24
      pay-respects
      uv
    ];

    # applications
    # file.".local/share/applications/wezterm.desktop" = {
    #   executable = true;
    #   text = ''
    #     [Desktop Entry]
    #     Type=Application
    #     Name=WezTerm
    #     GenericName=Terminal Emulator
    #     Comment=GPU-accelerated cross-platform terminal emulator
    #     Exec=wezterm
    #     Icon=org.wezfurlong.wezterm
    #     Terminal=false
    #     Categories=System;TerminalEmulator;Development;
    #   '';
    # };
    #
    # file.".local/share/applications/ghostty.desktop" = {
    #   executable = true;
    #   text = ''
    #     [Desktop Entry]
    #     Type=Application
    #     Name=Ghostty
    #     GenericName=Terminal Emulator
    #     Comment=A terminal emulator for the modern age
    #     Exec=ghostty
    #     Icon=com.mitchellh.ghostty
    #     Terminal=false
    #     Categories=System;TerminalEmulator;Development;
    #   '';
    # };
  };

  services.flatpak = {
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
    packages = [
      "org.deskflow.deskflow"
      "com.ranfdev.DistroShelf"
      "it.mijorus.gearlever"
      # "org.inkscape.Inkscape"
      # "org.gimp.GIMP"
      # "com.google.Chrome"
      "com.jeffser.Alpaca"
      "com.jeffser.Alpaca.Plugins.Ollama"
      "io.podman_desktop.PodmanDesktop"
      "com.visualstudio.code"
    ];
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    bat = {
      enable = true;
    };
    carapace = {
      enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
    };
    fd = {
      enable = true;
    };
    fzf = {
      enable = true;
    };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
    git = {
      enable = true;
      lfs = {
        enable = true;
      };
      maintenance = {
        enable = true;
      };
      settings = {
        user = {
          name = "Simon Ho";
        };
        core = {
          autocrlf = "input";
        };
        rerere = {
          enabled = true;
        };
        column = {
          ui = "auto";
        };
        branch = {
          sort = "-committerdate";
        };
        fetch = {
          writeCommitGraph = true;
        };
      };
    };
    home-manager = {
      enable = true;
    };
    ripgrep = {
      enable = true;
    };
    starship = {
      enable = true;
    };
    tealdeer = {
      enable = true;
    };
    yazi = {
      enable = true;
      package = inputs.yazi.packages.${system}.default.override { _7zz = pkgs._7zz; };
    };
    zoxide = {
      enable = true;
    };
  };

  # symlinks
  home.file.".codex" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/codex";
    force = true;
  };

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    force = true;
  };
  xdg.configFile."wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
    force = true;
  };
  xdg.configFile."yazi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/yazi";
    force = true;
  };
  xdg.configFile."lazygit" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazygit";
    force = true;
  };
  xdg.configFile."mcphub" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/mcphub";
    force = true;
  };
  xdg.configFile."fzf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fzf";
    force = true;
  };
  xdg.configFile."starship.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship.toml";
    force = true;
  };

}
