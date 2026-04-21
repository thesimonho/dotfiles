return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "js-debug-adapter",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "jsdoc",
        "javascript",
        "typescript",
      },
    },
  },
  {
    "dmmulroy/ts-error-translator.nvim",
    lazy = true,
    ft = { "typescript", "typescriptreact", "vue" },
    opts = {
      auto_attach = true,
      servers = {
        "astro",
        "svelte",
        "ts_ls",
        "typescript-tools",
        "volar",
        "vtsls",
      },
    },
  },
}
