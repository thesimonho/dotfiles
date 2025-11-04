return {
  {
    "mason-org/mason.nvim",
    keys = {
      { "<leader>cm", vim.NIL },
    },
    opts = {
      ensure_installed = {
        -- lsp
        "emmet-language-server",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },
}
