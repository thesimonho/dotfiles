local icons = require("config.constants").icons

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
      icons = icons,
    },
  },

  -- submodules
  { import = "plugins.colourschemes" },
  { import = "plugins.languages" },
}
