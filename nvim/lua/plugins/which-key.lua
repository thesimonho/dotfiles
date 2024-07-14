local utils = require("config.utils")

return {
  "folke/which-key.nvim",
  opts = {
    show_help = false,
    icons = {
      group = "",
    },
    preset = "helix",
    win = {
      title = false,
      border = utils.border_chars_outer_thin,
      padding = { 0, 0 },
    },
    layout = {
      align = "left",
    },
    spec = {
      { "<leader>?", name = "Buffer keymaps" },
      { "<leader>q", name = "quit" },
      { "<leader>x", name = "diagnostics" },
      { "<leader>f", name = "find" },
    },
  },
}
