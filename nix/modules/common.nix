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
      ast-grep
      lazydocker
      lazygit
      lazyjournal
      lua54Packages.luarocks
      neovim
      nixd
      nixfmt-rfc-style
      pay-respects
      pkgsUnstable.snitch
      wl-clipboard
      uv
      # cmake
      # docker
      # nerd-fonts.caskaydia-cove
      # nerd-fonts.fira-code
      # nerd-fonts.jetbrains-mono
      # nerd-fonts.symbols-only
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
      # "org.inkscape.Inkscape"
      # "org.gimp.GIMP"
      # "com.google.Chrome"
      "org.deskflow.deskflow"
      "com.ranfdev.DistroShelf"
      "it.mijorus.gearlever"
      "com.jeffser.Alpaca"
      "com.jeffser.Alpaca.Plugins.Ollama"
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
    eza = {
      enable = true;
      colors = "always";
      icons = "always";
      extraOptions = [
        "--hyperlink"
        "--group-directories-first"
        "--header"
      ];
      theme = {
        filekinds = {
          symlink = {
            is_italic = true;
          };
        };
        symlink_path = {
          is_italic = true;
        };
        broken_symlink_path = {
          is_italic = true;
        };
        broken_path_overlay = {
          is_italic = true;
        };
      };
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
    mise = {
      enable = true;
      package = pkgsUnstable.mise;
      globalConfig = {
        tools = {
          node = "24";
          python = "3.14";
          go = "1.25";
          rust = "1.92";
        };
        settings = {
          env_file = ".env";
          trusted_config_paths = [
            "~"
            "/run/media/Projects"
          ];
          idiomatic_version_file_enable_tools = [
            "node"
            "go"
            "python"
            "terraform"
          ];
          auto_install = true;
          not_found_auto_install = true;
          status = {
            missing_tools = "if_other_versions_installed";
            show_env = false;
            show_tools = false;
          };
          python.uv_venv_auto = true;
        };
      };
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
      initLua = ''
        require("git"):setup()
        th.git = th.git or {}
        th.git.modified_sign = " "
        th.git.deleted_sign = " "
        th.git.added_sign = " "
        th.git.untracked_sign = "󰞋 "
        th.git.ignored_sign = "󰿠 "
        th.git.updated_sign = " "

        require("full-border"):setup {
          type = ui.Border.ROUNDED,
        }
      '';
      settings = {
        mgr = {
          ratio = [
            1
            4
            3
          ];
          sort_by = "natural";
          sort_dir_first = true;
          sort_translit = true;
          show_hidden = true;
          show_symlink = true;
          mouse_events = [
            "click"
            "scroll"
          ];
        };
        preview = {
          wrap = "no";
        };
        opener = {
          edit = [
            {
              run = ''${"EDITOR:-nvim"} "$@"'';
              desc = "$EDITOR";
              block = true;
              for = "unix";
            }
            {
              run = "nvim %*";
              desc = "nvim";
              block = true;
              for = "windows";
            }
            {
              run = ''code "$@"'';
              orphan = true;
              desc = "code";
              for = "unix";
            }
            {
              run = "code %*";
              orphan = true;
              desc = "code";
              for = "windows";
            }
          ];
        };
        which = {
          sort_by = "none";
          sort_sensitive = false;
          sort_reverse = false;
          sort_translit = true;
        };
        plugin = {
          prepend_fetchers = [
            {
              id = "git";
              name = "*";
              run = "git";
            }
            {
              id = "git";
              name = "*/";
              run = "git";
            }
          ];
        };
      };
      keymap = {
        mgr = {
          prepend_keymap = [
            {
              on = "<C-f>";
              run = "plugin fzf";
              desc = "Jump to a file/directory via fzf";
            }
            {
              on = "z";
              run = "plugin zoxide";
              desc = "Jump to a directory via zoxide";
            }
            {
              on = "p";
              run = "plugin smart-paste";
              desc = "Paste into the hovered directory or CWD";
            }
            {
              on = [
                "c"
                "m"
              ];
              run = "plugin chmod";
              desc = "Change file permissions";
            }
          ];
        };
        input = {
          prepend_keymap = [
            {
              on = "<Esc>";
              run = "close";
              desc = "Cancel input";
            }
          ];
        };
      };
      plugins = {
        full-border = pkgs.yaziPlugins.full-border;
        git = pkgs.yaziPlugins.git;
        smart-paste = pkgs.yaziPlugins.smart-paste;
        sudo = pkgs.yaziPlugins.sudo;
        chmod = pkgs.yaziPlugins.chmod;
        toggle-pane = pkgs.yaziPlugins.toggle-pane;
      };
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
  xdg.configFile."ghostty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
    force = true;
  };
  xdg.configFile."wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
    force = true;
  };
  xdg.configFile."lazygit" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazygit";
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
