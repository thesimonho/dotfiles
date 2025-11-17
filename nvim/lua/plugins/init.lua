local constants = require("config.constants")

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
      icons = constants.icons,
    },
  },

  -- submodules
  { import = "plugins.colourschemes" },
  { import = "plugins.languages" },
}
