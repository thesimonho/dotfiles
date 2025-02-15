return {
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    dev = true,
    branch = "v2",
    priority = 1000,
    opts = {
      transparent = false,
      plugins = {
        bufferline = false,
        mini = false,
        nvim_cmp = false,
        nvim_tree = false,
        telescope = false,
      },
    },
  },
}
