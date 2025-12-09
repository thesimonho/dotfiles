return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- lsp
        "emmet-language-server",
      },
    },
  },
  {
    "olrtg/nvim-emmet",
    ft = { "html", "css", "sass", "scss", "vue", "javascriptreact", "typescriptreact" },
    keys = {
      {
        "<localleader>e",
        function()
          require("nvim-emmet").wrap_with_abbreviation()
        end,
        mode = { "n", "v" },
        desc = "Emmet Wrap",
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
