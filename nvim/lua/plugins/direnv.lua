return {
  "NotAShelf/direnv.nvim",
  init = function()
    local wk = require("which-key")
    wk.add({
      { "<localleader>d", group = "direnv", icon = "󱃷" },
    })
  end,
  opts = {
    autoload_direnv = true,
    statusline = {
      enabled = true,
      icon = "󱃷",
    },
    notifications = {
      silent_autoload = true,
    },
    keybindings = {
      allow = "<localleader>da",
      deny = "<localleader>dd",
      reload = "<localleader>dr",
      edit = "<localleader>de",
    },
  },
}
