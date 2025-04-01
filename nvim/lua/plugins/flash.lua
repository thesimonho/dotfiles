return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    search = {
      multi_window = false,
      incremental = true,
    },
    jump = {
      nohlsearch = false,
    },
    label = {
      uppercase = false,
      before = true,
      after = false,
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
        enabled = true,
        jump_labels = true,
        multi_line = false,
      },
    },
  },
}
