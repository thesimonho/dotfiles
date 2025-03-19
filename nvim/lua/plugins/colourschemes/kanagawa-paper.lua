return {
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    dev = true,
    priority = 1000,
    opts = {
      dim_inactive = true,
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
