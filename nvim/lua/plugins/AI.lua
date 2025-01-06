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

require("snacks").toggle
  .new({
    name = "AI",
    get = function()
      return require("supermaven-nvim.api").is_running()
    end,
    set = function()
      require("supermaven-nvim.api").toggle()
    end,
  })
  :map("<leader>ux")

return M
