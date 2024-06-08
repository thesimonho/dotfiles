return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    search = {
      multi_window = false,
    },
    label = {
      uppercase = false,
      rainbow = {
        enabled = true,
        shade = 5,
      },
    },
    modes = {
      search = {
        enabled = true,
      },
      char = {
        enabled = false,
        jump_labels = true,
      },
    },
  },
}
