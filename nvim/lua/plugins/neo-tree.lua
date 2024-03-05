local M = {
  "nvim-neo-tree/neo-tree.nvim",
  enabled = true,
  cmd = "Neotree",
  keys = {
    { "<leader>fe", vim.NIL },
    { "<leader>fE", vim.NIL },
    { "<leader>E", vim.NIL },
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
      end,
      desc = "Explorer",
    },
  },
  opts = {
    close_if_last_window = true,
    popup_border_style = "single",
    enable_git_status = true,
    enable_modified_markers = true,
    enable_diagnostics = false,
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
      icon = {
        folder_closed = "",
        folder_open = "",
        folder_empty = "",
        folder_empty_open = "",
      },
      git_status = {
        symbols = {
          -- Change type
          added = "",
          deleted = "",
          modified = "",
          -- renamed = "󰾟",
          -- Status type
          untracked = "",
          ignored = "",
          -- unstaged = "󰞋",
          staged = "",
          conflict = "",
        },
      },
    },
    window = {
      position = "left",
      width = 35,
    },
    filesystem = {
      bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
      cwd_target = {
        sidebar = "window", -- match this to however cd is set elsewhere (tab, window, global)
      },
      filtered_items = {
        visible = false, -- when true, they will just be displayed differently than normal items
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = true, -- only works on Windows for hidden files/directories
      },
      follow_current_file = {
        enabled = true,
      },
      hide_by_name = {
        ".DS_Store",
        "thumbs.db",
      },
      use_libuv_file_watcher = true, -- This will use the OS level file watchers to detect changes
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
    },
  },
}

return M
