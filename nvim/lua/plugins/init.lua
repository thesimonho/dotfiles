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
  { "akinsho/bufferline.nvim", enabled = false },
}
