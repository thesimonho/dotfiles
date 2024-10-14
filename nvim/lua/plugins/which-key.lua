local style = require("utils.style")

return {
  "folke/which-key.nvim",
  opts = {
    show_help = false,
    show_keys = false,
    preset = "helix",
    delay = 100,
    win = {
      title = true,
      border = style.border_chars_outer_thin,
      padding = { 1, 0 },
    },
    layout = {
      align = "left",
    },
    icons = {
      group = "",
      keys = {
        C = "ᴄᴛʀʟ ",
        M = "ᴀʟᴛ ",
        D = "ᴄᴏᴍᴍᴀɴᴅ ",
        S = "󰘶 ",
      },
    },
    plugins = {
      marks = false,
      registers = false,
      spelling = { enabled = false },
    },
    spec = {
      { "<localleader>", name = "Local" },
      { "<leader>?", name = "Buffer keymaps" },
      { "<leader>q", name = "quit" },
      { "<leader>x", name = "diagnostics" },
      { "<leader>f", name = "find" },
    },
  },
}
