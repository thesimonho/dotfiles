{ pkgs, ... }:

{
  programs.yazi = {
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
}
