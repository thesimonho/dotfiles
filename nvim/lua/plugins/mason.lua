return {
  "williamboman/mason.nvim",
  keys = {
    { "<leader>cm", vim.NIL },
  },
  opts = {
    ensure_installed = {
      "graphql-language-service-cli",
      "lua-language-server",
      "terraform-ls",
      "typescript-language-server",
      "vim-language-server",
      "yaml-language-server",
      "vue-language-server",

      -- linters
      "eslint_d",
      "markdownlint",

      -- formatters
      "prettierd",
      "stylua",
    },
  },
}
