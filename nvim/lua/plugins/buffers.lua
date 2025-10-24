return {
  { "akinsho/bufferline.nvim", enabled = false },
  { "folke/persistence.nvim", enabled = false },
  {
    "olimorris/persisted.nvim",
    event = "BufReadPre",
    init = function()
      -- save barbar buffer order before saving session
      vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "PersistedSavePre",
        group = vim.api.nvim_create_augroup("PersistedHooks", {}),
        callback = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
        end,
      })
    end,
    opts = {
      follow_cwd = true,
      use_git_branch = true,
      autoload = true,
      should_save = function()
        if vim.bo.filetype == "snacks_dashboard" then
          return false
        end
        return true
      end,
      on_autoload_no_session = function()
        vim.notify("No existing session to load.")
        vim.cmd("Neotree")
      end,
    },
  },
  {
    "tiagovla/scope.nvim",
    event = "LazyFile",
    opts = {
      hooks = {
        -- save session on tab leave and close
        pre_tab_leave = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabLeavePre" })
          pcall(require("persisted").save)
        end,
        pre_tab_close = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabLeavePre" })
          pcall(require("persisted").save)
        end,
        post_tab_enter = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabEnterPost" })
        end,
      },
    },
  },
  {
    "romgrk/barbar.nvim",
    event = "LazyFile",
    keys = {
      { "<leader>bp", "<cmd>BufferPin<cr>", desc = "Pin Buffer" },
      { "<leader>bD", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", desc = "Delete Other Buffers" },
      {
        "<leader>bx",
        function()
          local alt = vim.fn.bufnr("#")
          if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.api.nvim_buf_is_loaded(alt) then
            vim.api.nvim_buf_delete(alt, { force = false })
          else
            print("No valid alternate buffer")
          end
        end,
        desc = "Delete Alternate Buffer",
      },
      { "<S-h>", "<cmd>BufferPrevious<cr>", desc = "Previous Buffer" },
      { "<S-l>", "<cmd>BufferNext<cr>", desc = "Next Buffer" },
    },
    opts = {
      focus_on_close = "left",
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
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    keys = {
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to down split",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to up split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split",
      },
    },
    opts = {
      at_edge = "stop",
      cursor_follows_swapped_bufs = true,
      disable_multiplexer_nav_when_zoomed = false,
      zellij_move_focus_or_tab = false,
      log_level = "warn",
    },
  },
}
