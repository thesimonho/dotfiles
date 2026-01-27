local constants = require("config.constants")

local function open_in_oil(state)
  local node = state.tree:get_node()
  if node.type == "directory" then
    local path = node:get_id()
    require("neo-tree.command").execute({ action = "close" })
    vim.cmd.Oil(path)
  else
    vim.notify("Not a directory: " .. node.name, vim.log.levels.WARN)
  end
end

return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    lazy = false,
    keys = {
      { "<leader>E", "<CMD>Oil<CR>", desc = "Oil" },
    },
    opts = {
      default_file_explorer = false,
      delete_to_trash = true,
      watch_for_changes = true,
      keymaps = {
        ["?"] = { "actions.show_help", mode = "n" },
        ["<Esc>"] = { "actions.close", mode = "n" },
        ["q"] = { "actions.close", mode = "n" },
        ["<BS>"] = { "actions.parent", mode = "n" },
      },
    },
  },
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
      popup_border_style = constants.border_chars_outer_thin,
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
        created = {
          format = "relative",
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
        symlink_target = {
          enabled = true,
          text_format = " ➛ %s", -- %s will be replaced with the symlink target's path.
        },
        type = {
          enabled = false,
          required_width = 50, -- min width of window required to show this column
        },
        file_size = {
          enabled = false,
          required_width = 60, -- min width of window required to show this column
        },
        last_modified = {
          enabled = true,
          format = "relative",
          required_width = 60, -- min width of window required to show this column
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
            added = constants.icons.git.added,
            deleted = constants.icons.git.removed,
            modified = constants.icons.git.modified,
            renamed = "  ",
            -- Status type
            untracked = "󰞋  ",
            ignored = "󰿠  ",
            unstaged = "  ",
            staged = "  ",
            conflict = "  ",
          },
        },
      },
      window = {
        position = "float",
        popup = { -- settings that apply to float position only
          position = { col = "99%", row = "3" },
          size = function()
            return {
              width = "35%",
              height = vim.o.lines - 6,
            }
          end,
          title = "Neo-tree",
        },
        mappings = {
          ["<cr>"] = "open_with_window_picker",
          ["<2-LeftMouse>"] = "open_with_window_picker",
          ["<tab>"] = { "toggle_node" },
          ["v"] = "open_vsplit",
          ["s"] = {
            function()
              require("flash").jump()
            end,
            desc = "flash",
          },
        },
      },
      filesystem = {
        bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
        cwd_target = {
          sidebar = "window", -- match this to however cd is set elsewhere (tab, window, global)
        },
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          visible = false, -- when true, they will just be displayed differently than normal items
          hide_hidden = false, -- only works on Windows for hidden files/directories
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        always_show_by_pattern = { -- uses glob style patterns
          ".env*", -- BUG: this is not working so have to set hide_gitignored = false
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
            ["E"] = {
              function(state)
                open_in_oil(state)
              end,
              desc = "open_in_oil",
            },
            ["f"] = "fuzzy_finder",
            ["F"] = "fuzzy_finder_directory",
            ["/"] = "",
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
  {
    "s1n7ax/nvim-window-picker",
    event = "VeryLazy",
    opts = {
      hint = "floating-big-letter",
      selection_chars = "asdf",
      show_prompt = false,
      picker_config = {
        handle_mouse_click = true,
        floating_big_letter = {
          font = "ansi-shadow",
        },
      },
      filter_rules = {
        autoselect_one = true,
        include_current_win = true,
        include_unfocusable_windows = false,
        bo = {
          filetype = { "neo-tree", "notify", "snacks_notif", "grug-far" },
          buftype = { "terminal" },
        },
      },
    },
  },
}
