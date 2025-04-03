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
      before = false,
      after = true,
      style = "overlay",
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
        enabled = false, -- nice, but operator pending mode doesnt work like normal vim
        jump_labels = true,
        multi_line = false,
      },
    },
  },
}
