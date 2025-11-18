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
    init = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "v" },
        { "<localleader>e", group = "Emmet" },
      })
    end,
    keys = {
      {
        "<localleader>ew",
        function()
          require("nvim-emmet").wrap_with_abbreviation()
        end,
        mode = { "n", "v" },
        desc = "Wrap with Abbreviation",
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
