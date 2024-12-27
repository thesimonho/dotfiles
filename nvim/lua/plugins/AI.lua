M = {
  {
    "supermaven-inc/supermaven-nvim",
    lazy = false, -- required otherwise color setting wont work
    opts = {
      keymaps = {
        accept_suggestion = "<M-l>",
        clear_suggestion = "<M-e>",
        accept_word = "<M-h>",
      },
      color = {
        suggestion_color = "#666666",
        cterm = 244,
      },
      disable_inline_completion = false,
    },
  },
}

return M
