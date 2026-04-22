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
}
