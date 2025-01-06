return {
  "folke/trouble.nvim",
  init = function()
    local wk = require("which-key")
    wk.add({ "<leader>cS", name = "LSP references (Trouble)" })
  end,
  opts = {
    focus = true, -- Focus the window when opened
    follow = true, -- Follow the current item
    indent_guides = true, -- show indent guides
    modes = {
      symbols = {
        focus = true,
        win = { position = "right", size = 40 },
      },
    },
  },
}
