return {
  {
    "tiagovla/scope.nvim",
    event = "LazyFile",
    opts = {
      hooks = {
        pre_tab_leave = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabLeavePre" })
        end,
        post_tab_enter = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabEnterPost" })
        end,
      },
    },
  },
  {
    "romgrk/barbar.nvim",
    enabled = true,
    event = "LazyFile",
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader><space>", "<Cmd>BufferPick<CR>", desc = "Pick buffer" },
      { "<leader>bb", "<Cmd>lua require('telescope.builtin').buffers()<CR>", desc = "Buffer list" },
      { "<leader>bo", "<cmd>e #<cr>", desc = "Other buffer" },
      { "<leader>bn", "<cmd>vnew<cr>", desc = "New buffer" },
      { "<leader>bp", "<cmd>BufferPin<cr>", desc = "Pin buffer" },
      { "<leader>bD", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", desc = "Delete other buffers" },
      { "<leader>b1", "<Cmd>BufferGoto 1<CR>", desc = "Buffer 1" },
      { "<leader>b2", "<Cmd>BufferGoto 2<CR>", desc = "Buffer 2" },
      { "<leader>b3", "<Cmd>BufferGoto 3<CR>", desc = "Buffer 3" },
      { "<leader>b4", "<Cmd>BufferGoto 4<CR>", desc = "Buffer 4" },
    },
    opts = {
      focus_on_close = "previous",
      highlight_alternate = true,
      highlight_inactive_file_icons = false,
      highlight_visible = false,
      separator_at_end = false,
      maximum_length = 20,
      icons = {
        buffer_index = true,
        buffer_number = false,
        pinned = { button = "", filename = true },
        alternate = { filetype = { custom_colors = true } },
        diagnostics = {
          [vim.diagnostic.severity.ERROR] = { enabled = false },
          [vim.diagnostic.severity.WARN] = { enabled = false },
          [vim.diagnostic.severity.INFO] = { enabled = false },
          [vim.diagnostic.severity.HINT] = { enabled = false },
        },
        gitsigns = {
          added = { enabled = false },
          changed = { enabled = false },
          deleted = { enabled = false },
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    enabled = false,
    event = "LazyFile",
    keys = {
      { "<leader>bl", vim.NIL },
      { "<leader>br", vim.NIL },
      { "<leader><space>", "<Cmd>BufferLinePick<CR>", desc = "Pick buffer" },
      { "<leader>bb", "<Cmd>lua require('telescope.builtin').buffers()<CR>", desc = "Buffer list" },
      { "<leader>bo", "<cmd>e #<cr>", desc = "Other buffer" },
      { "<leader>bn", "<cmd>vnew<cr>", desc = "New buffer" },
      { "<leader>bD", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
      { "<leader>b1", "<Cmd>BufferLineGoToBuffer 1<CR>", desc = "Buffer 1" },
      { "<leader>b2", "<Cmd>BufferLineGoToBuffer 2<CR>", desc = "Buffer 2" },
      { "<leader>b3", "<Cmd>BufferLineGoToBuffer 3<CR>", desc = "Buffer 3" },
      { "<leader>b4", "<Cmd>BufferLineGoToBuffer 4<CR>", desc = "Buffer 4" },
    },
    opts = {
      options = {
        close_command = function(n)
          require("mini.bufremove").delete(n, false)
        end,
        right_mouse_command = function(n)
          require("mini.bufremove").delete(n, false)
        end,
        mode = "buffers",
        numbers = function(opts)
          return string.format("%s", opts.ordinal)
        end,
        themable = true,
        indicator = {
          style = "icon",
          icon = "▎", -- this should be omitted if indicator style is not 'icon'
        },
        hover = {
          enabled = false,
        },
        buffer_close_icon = "",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        truncate_names = true, -- whether or not tab names should be truncated
        color_icons = true,
        show_buffer_icons = true, -- disable filetype icons for buffers
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        separator_style = "thick",
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        sort_by = "extension",
        diagnostics = false,
        style_preset = {
          require("bufferline").style_preset.no_italic,
          require("bufferline").style_preset.no_bold,
        },
      },
    },
  },
}
