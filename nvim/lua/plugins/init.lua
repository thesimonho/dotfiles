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
  { "folke/persistence.nvim", enabled = false },
  { "echasnovski/mini.pairs", enabled = false },
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
}
