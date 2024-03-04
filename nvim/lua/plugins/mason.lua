return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
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

