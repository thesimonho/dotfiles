return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>dpt", "<cmd>lua Snacks.profiler.pick()<cr>", desc = "Toggle" },
      {
        "<leader>qp",
        function()
          local flag_file = vim.fn.stdpath("state") .. "/startup_profiler"
          vim.fn.writefile({}, flag_file)
          vim.notify("Profiler will run on next startup")
        end,
        desc = "Profile Next Startup",
      },
    },
    init = function()
      _G.dd = function(...)
        Snacks.debug.inspect(...)
      end
      _G.bt = function()
        Snacks.debug.backtrace()
      end
      vim.print = _G.dd
    end,
    opts = {
      gitbrowse = {
        notify = true,
        remote_patterns = {
          { "^(https?://.*)%.git$", "%1" },
          { "^git@personal%-github%.com:(.+)%.git$", "https://github.com/%1" },
          { "^git@(.+):(.+)%.git$", "https://%1/%2" },
          { "^git@(.+):(.+)$", "https://%1/%2" },
          { "^git@(.+)/(.+)$", "https://%1/%2" },
          { "^ssh://git@(.*)$", "https://%1" },
          { "^ssh://([^:/]+)(:%d+)/(.*)$", "https://%1/%3" },
          { "^ssh://([^/]+)/(.*)$", "https://%1/%2" },
          { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
          { "^https://%w*@(.*)", "https://%1" },
          { "^git@(.*)", "https://%1" },
          { ":%d+", "" },
          { "%.git$", "" },
        },
      },
      notifier = {
        margin = { top = 1, right = 1, bottom = 1 },
        style = "compact",
      },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      indent = {
        indent = {
          enabled = true, -- enable indent guides
          char = "│",
          only_scope = true, -- only show indent guides of the scope
          only_current = true, -- only show indent guides in the current window
          hl = "SnacksIndent",
        },
        scope = {
          enabled = false, -- enable highlighting the current scope
          hl = "SnacksIndentScope",
        },
        chunk = {
          enabled = true,
          only_current = true,
          hl = "SnacksIndentChunk",
          char = {
            corner_top = "╭",
            corner_bottom = "╰",
            horizontal = "─",
            vertical = "│",
            arrow = "›",
          },
        },
        filter = function(buf)
          return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype ~= "bigfile"
        end,
        priority = 200,
      },
      scroll = {
        filter = function(buf)
          return vim.g.snacks_scroll ~= false
            and vim.b[buf].snacks_scroll ~= false
            and vim.bo[buf].buftype ~= "terminal"
            and vim.bo[buf].filetype ~= "bigfile"
        end,
      },
      lazygit = {
        configure = true,
        theme = {
          activeBorderColor = { fg = "lualine_b_normal", bold = true },
          inactiveBorderColor = { fg = "Comment" },
          cherryPickedCommitBgColor = { fg = "lualine_b_normal" },
          cherryPickedCommitFgColor = { fg = "Function" },
          defaultFgColor = { fg = "Normal" },
          optionsTextColor = { fg = "Statement" },
          searchingActiveBorderColor = { fg = "Search", bold = true },
          selectedLineBgColor = { bg = "CursorLineAlt" },
          unstagedChangesColor = { fg = "DiagnosticError" },
        },
      },
    },
  },
}
