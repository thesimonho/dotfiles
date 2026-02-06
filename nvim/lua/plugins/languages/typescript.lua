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
}
