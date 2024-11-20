return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
    },
  },
  -- submodules
  { import = "plugins.colourschemes" },
  { import = "plugins.languages" },
  -- disabled
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  { "echasnovski/mini.pairs", enabled = false },
  { "akinsho/bufferline.nvim", enabled = false },
}
