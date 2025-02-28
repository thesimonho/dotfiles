local hour = os.date("*t").hour
local theme = (hour >= 7 and hour < 19) and "canvas" or "ink"

return {
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    dev = true,
    branch = "v2",
    priority = 1000,
    opts = {
      theme = theme,
      auto_plugins = true,
    },
  },
}
