local style = require("utils.style")
local icons = require("lazyvim.config").icons

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    keys = {
      { "<leader>fe", vim.NIL },
      { "<leader>fE", vim.NIL },
      { "<leader>E", vim.NIL },
      { "<leader>be", vim.NIL },
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({
            position = "float",
            toggle = false,
            reveal_force_cwd = true,
            dir = vim.uv.cwd(),
          })
        end,
        desc = "Explorer",
      },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = style.border_chars_outer_thin,
      enable_git_status = true,
      enable_modified_markers = true,
      enable_opened_markers = true,
      enable_diagnostics = true,
      sort_case_insensitive = true,
      default_component_configs = {
        indent = {
          with_markers = true,
          with_expanders = true,
        },
        modified = {
          symbol = " ",
          highlight = "NeoTreeModified",
        },
        name = {
          trailing_slash = false,
          use_git_status_colors = true,
          highlight_opened_files = true,
          highlight = "NeoTreeFileName",
        },
        type = {
          enabled = true,
          required_width = 50, -- min width of window required to show this column
        },
        file_size = {
          enabled = true,
          required_width = 60, -- min width of window required to show this column
        },
        last_modified = {
          enabled = true,
          required_width = 100, -- min width of window required to show this column
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "",
          folder_empty_open = "",
        },
        diagnostics = {
          symbols = {
            -- disable certain diagnostic levels
            hint = "",
            info = "",
            warn = "",
          },
        },
        git_status = {
          symbols = {
            -- Change type
            added = icons.git.added,
            deleted = icons.git.removed,
            modified = icons.git.modified,
            renamed = "  ",
            -- Status type
            untracked = "  ",
            ignored = "  ",
            unstaged = "  ",
            staged = "  ",
            conflict = "  ",
          },
        },
      },
      window = {
        position = "float",
        popup = { -- settings that apply to float position only
          size = {
            height = "80%",
            width = "40%",
          },
          position = "50%", -- 50% means center it
          title = "Neo-tree",
        },
        mappings = {
          ["<tab>"] = { "toggle_node" },
          ["v"] = "open_vsplit",
          ["s"] = {
            function()
              require("flash").jump()
            end,
            config = { title = "flash" },
          },
        },
      },
      filesystem = {
        bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
        cwd_target = {
          sidebar = "window", -- match this to however cd is set elsewhere (tab, window, global)
        },
        filtered_items = {
          visible = false, -- when true, they will just be displayed differently than normal items
          hide_dotfiles = true,
          hide_gitignored = true,
          hide_hidden = true, -- only works on Windows for hidden files/directories
        },
        follow_current_file = {
          enabled = true,
        },
        hide_by_pattern = {
          "^./.git/",
        },
        never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
          ".DS_Store",
          "thumbs.db",
          "node_modules",
        },
        use_libuv_file_watcher = true,
        window = {
          mappings = {
            ["<A-h>"] = "toggle_hidden",
          },
          fuzzy_finder_mappings = {
            ["<C-j>"] = "move_cursor_down",
            ["<C-k>"] = "move_cursor_up",
          },
        },
      },
      buffers = {
        follow_current_file = {
          enabled = true,
        },
        group_empty_dirs = false,
      },
      git_status = {
        window = {
          position = "float",
        },
      },
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function(args)
            if args.position == "left" or args.position == "right" then
              vim.cmd("wincmd =")
            end
          end,
        },
        {
          event = "neo_tree_window_after_close",
          handler = function(args)
            if args.position == "left" or args.position == "right" then
              vim.cmd("wincmd =")
            end
          end,
        },
        {
          event = "file_moved",
          handler = function(args)
            Snacks.rename.on_rename_file(args.source, args.destination)
          end,
        },
        {
          event = "file_renamed",
          handler = function(args)
            Snacks.rename.on_rename_file(args.source, args.destination)
          end,
        },
      },
    },
  },
}
