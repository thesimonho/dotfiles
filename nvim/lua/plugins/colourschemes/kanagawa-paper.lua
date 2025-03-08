return {
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    dev = true,
    priority = 1000,
    opts = {
      cache = false,
      auto_plugins = true,
      integrations = {
        wezterm = {
          enabled = true,
        },
      },
    },
  },
}
