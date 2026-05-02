{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  dotfiles = config.my.dotfilesPath;
  meta = import ../secrets/meta.nix;
  selectedIdentities = lib.filterAttrs (name: _: lib.elem name config.my.identities) meta.identities;

  # Generate git identity config files from selected identities
  gitIdentityFiles = lib.mapAttrs' (name: id: {
    name = "git/identity-${name}";
    value = {
      text = ''
        [user]
          email = ${id.email}
      ''
      + lib.optionalString (id.gpg != null && id.gpg.sign) ''
          signingKey = ${id.gpg.keyId}
        [commit]
          gpgSign = true
        [tag]
          gpgSign = true
      '';
    };
  }) selectedIdentities;

  # Generate includeIf rules that route git identity based on remote URL
  # Each identity can have multiple patterns (SSH and HTTPS)
  gitIncludes = lib.concatLists (
    lib.mapAttrsToList (
      name: id:
      map (pattern: {
        condition = "hasconfig:remote.*.url:${pattern}";
        path = "${config.xdg.configHome}/git/identity-${name}";
      }) id.remotePatterns
    ) selectedIdentities
  );
in
{
  imports = [ ./zsh.nix ];
  targets.genericLinux.enable = isLinux;
  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.autostart.enable = true;

  home = {
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "en_US.UTF-8";
      COLORTERM = "truecolor";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    }
    // lib.optionalAttrs (config.my.browser.executable != null) {
      CHROME_EXECUTABLE = config.my.browser.executable;
    };
    sessionPath = [
      "${config.home.homeDirectory}/.npm-global/bin"
      "${config.home.homeDirectory}/.local/share/nvim/mason/bin"
      "${config.home.homeDirectory}/.local/bin"
    ];
    shell.enableShellIntegration = true;
  };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    git = {
      enable = true;
      lfs = {
        enable = true;
      };
      maintenance = {
        enable = true;
      };
      includes = gitIncludes;
      settings = {
        user = {
          name = "Simon Ho";
        };
        init = {
          defaultBranch = "main";
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
        merge = {
          conflictStyle = "zdiff3";
        };
        credential = {
          helper = "${pkgs.gh}/bin/gh auth git-credential";
          useHttpPath = true;
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
          python = "3.14.4";
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
          python.uv_venv_auto = "create|source";
        };
      };
    };
    yazi = {
      enable = true;
      initLua = ''
        require("git"):setup()
        th.git = th.git or {}
        th.git.modified_sign = " "
        th.git.deleted_sign = " "
        th.git.added_sign = " "
        th.git.untracked_sign = "󰞋 "
        th.git.ignored_sign = "󰿠 "
        th.git.updated_sign = " "

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
  };

  # config files: git identity configs and dotfile symlinks
  xdg.configFile = gitIdentityFiles // {
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
      force = true;
    };
    "ghostty" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
      force = true;
    };
    "wezterm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wezterm";
      force = true;
    };
    "lazygit" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lazygit";
      force = true;
    };
    "fzf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fzf";
      force = true;
    };
    "starship.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship.toml";
      force = true;
    };
  };
}
