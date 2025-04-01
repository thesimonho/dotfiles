return {
  {
    "lewis6991/satellite.nvim",
    opts = {
      current_only = true,
      width = 1,
      winblend = 0,
      excluded_filetypes = { "TelescopePrompt", "bigfile", "which-key" },
      handlers = {
        cursor = {
          enable = true,
          symbols = { "●" },
        },
        diagnostic = {
          enable = true,
          signs = {
            error = { LazyVim.config.icons.diagnostics.Error },
            warn = { LazyVim.config.icons.diagnostics.Warn },
            info = { LazyVim.config.icons.diagnostics.Info },
            hint = { LazyVim.config.icons.diagnostics.Hint },
          },
          min_severity = vim.diagnostic.severity.WARN,
        },
      },
    },
  },
}
