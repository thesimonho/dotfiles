return {
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    dev = true,
    priority = 1000,
    opts = {
      cache = false,
      dim_inactive = true,
      diag_background = true,
      auto_plugins = true,
      integrations = {
        wezterm = {
          enabled = true,
        },
      },
    },
  },
}
