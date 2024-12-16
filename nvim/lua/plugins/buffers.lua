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
  { -- restore buffers on session restore
    "folke/persistence.nvim",
    pre_save = function()
      vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
    end,
  },
  {
    "romgrk/barbar.nvim",
    event = "LazyFile",
    keys = {
      { "<leader><space>", "<Cmd>BufferPick<CR>", desc = "Pick buffer" },
      { "<leader>bp", "<cmd>BufferPin<cr>", desc = "Pin buffer" },
      { "<leader>bD", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", desc = "Delete other buffers" },
    },
    opts = {
      focus_on_close = "previous",
      highlight_alternate = true,
      highlight_inactive_file_icons = false,
      highlight_visible = false,
      separator_at_end = false,
      maximum_length = 30,
      icons = {
        buffer_index = true,
        buffer_number = false,
        pinned = { button = "", filename = true },
        alternate = { filetype = { custom_colors = true } },
        separator = { left = "▎", right = "▎" },
        diagnostics = {
          [vim.diagnostic.severity.ERROR] = { enabled = true },
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
}
