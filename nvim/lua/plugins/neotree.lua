local style = require("utils.style")
local icons = require("lazyvim.config").icons

local diff_files = function(state)
  local node = state.tree:get_node()

  state.clipboard = state.clipboard or {}
  state.diff_node = state.diff_node or nil
  state.diff_name = state.diff_name or nil

  if state.diff_node and state.diff_node ~= tostring(node.id) then
    local current_diff = node.id
    require("neo-tree.utils").open_file(state, state.diff_node, "tabnew")
    vim.cmd("vert diffs " .. current_diff)
    state.diff_node = nil
    state.diff_name = nil
    state.clipboard = {}
    require("neo-tree.ui.renderer").redraw(state)
  else
    local existing = state.clipboard[node.id]
    if existing and existing.action == "diff" then
      state.clipboard[node.id] = nil
      state.diff_node = nil
      state.diff_name = nil
      require("neo-tree.ui.renderer").redraw(state)
    else
      state.clipboard[node.id] = { action = "diff", node = node }
      state.diff_name = node.name
      state.diff_node = tostring(node.id)
      require("neo-tree.ui.renderer").redraw(state)
    end
  end
end

local function open_in_prev_win(state)
  local node = state.tree:get_node()
  local path = node:get_id()
  local prev_win = vim.g.neotree_prev_win
  require("neo-tree.command").execute({ action = "close" })
  if prev_win and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
  vim.cmd.edit(path)
end

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
          vim.g.neotree_prev_win = vim.api.nvim_get_current_win()
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
            added = icons.git.added,
            deleted = icons.git.removed,
            modified = icons.git.modified,
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
          ["<cr>"] = open_in_prev_win,
          ["<2-LeftMouse>"] = open_in_prev_win,
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
        filtered_items = {
          visible = false, -- when true, they will just be displayed differently than normal items
          hide_hidden = false, -- only works on Windows for hidden files/directories
          hide_dotfiles = false,
          hide_gitignored = true,
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
            ["D"] = {
              function(state)
                diff_files(state)
              end,
              desc = "diff_files",
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
}
