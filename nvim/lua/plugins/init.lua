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
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "folke/persistence.nvim", enabled = false },
  { "zbirenbaum/copilot-cmp", enabled = false },
  { "echasnovski/mini.pairs", enabled = false },
  { "nvim-treesitter/nvim-treesitter-context", enabled = false },
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
}
