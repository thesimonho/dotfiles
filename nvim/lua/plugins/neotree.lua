local utils = require("config.utils")

local get_node_path = function(node)
  local path = node.path
  if node.type == "file" then
    path = vim.loop.cwd()
  end
  return path
end

local M = {
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
            reveal = true,
            dir = vim.loop.cwd(),
          })
        end,
        desc = "Explorer",
      },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = utils.border_chars_outer_thin,
      enable_git_status = true,
      enable_modified_markers = true,
      enable_diagnostics = false,
      sort_case_insensitive = true,
      commands = {
        find_files_dir = function(state)
          local node = state.tree:get_node()
          require("telescope.builtin").find_files({ cwd = get_node_path(node) })
          vim.cmd("Neotree close")
        end,
        grep_dir = function(state)
          local node = state.tree:get_node()
          require("telescope.builtin").live_grep({ cwd = get_node_path(node) })
          vim.cmd("Neotree close")
        end,
      },
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
        mappings = {
          ["<tab>"] = { "toggle_node" },
          ["f"] = "find_files_dir",
          ["g"] = "grep_dir",
        },
      },
      filesystem = {
        bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
        cwd_target = {
          sidebar = "window", -- match this to however cd is set elsewhere (tab, window, global)
        },
        filtered_items = {
          visible = false, -- when true, they will just be displayed differently than normal items
          hide_dotfiles = false,
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
        use_libuv_file_watcher = false,
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
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.opt_local.number = true
            vim.opt_local.relativenumber = true
          end,
        },
      },
    },
  },
}

-- link neotree colours to nvim-tree for automatic theme support
-- https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Visual-Customizations#colour-scheme
vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { link = "NvimTreeFolderIcon" })
vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { link = "NvimTreeOpenedFolderName" })
vim.api.nvim_set_hl(0, "NeoTreeSymbolicLinkTarget", { link = "NvimTreeSymlink" })
vim.api.nvim_set_hl(0, "NeoTreeRootName", { link = "NvimTreeRootFolder" })
vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { link = "NvimTreeOpenedFile" })

return M
