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
      plugins = {
        aerial = false,
        bufferline = false,
        floaterm = false,
        gitgutter = false,
        incline = false,
        indent_blankline = false,
        mini = false,
        neogit = false,
        nvim_cmp = false,
        nvim_navic = false,
        nvim_spectre = false,
        nvim_tree = false,
        nvim_window_picker = false,
        octo = false,
        overseer = false,
        telescope = false,
      },
    },
  },
}
