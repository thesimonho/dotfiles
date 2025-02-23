local M = {
  {
    "AlejandroSuero/supermaven-nvim", -- TODO: fork until PR is merged
    lazy = false, -- required otherwise color setting wont work
    branch = "feature/exposing-suggestion-group",
    opts = {
      ignore_filetypes = { "neo-tree" },
      keymaps = {
        accept_suggestion = "<M-l>",
        clear_suggestion = "<M-e>",
        accept_word = "<M-h>",
      },
      color = {
        suggestion_group = "Comment",
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
