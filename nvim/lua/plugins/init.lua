return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
  -- submodules
  { import = "plugins.colourschemes" },
  { import = "plugins.languages" },
  -- disabled
  { "zbirenbaum/copilot-cmp", enabled = false },
  { "echasnovski/mini.pairs", enabled = false },
  { "echasnovski/mini.indentscope", enabled = false },
  { "nvim-treesitter/nvim-treesitter-context", enabled = false },
  { "nvim-pack/nvim-spectre", enabled = false },
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
}
