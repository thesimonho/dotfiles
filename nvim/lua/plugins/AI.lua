local get_comment_color = function()
  local hl = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local hex_color = string.format("#%06x", hl.fg)
  return hex_color
end

local M = {
  {
    "supermaven-inc/supermaven-nvim",
    lazy = false, -- required otherwise color setting wont work
    opts = {
      ignore_filetypes = { "neo-tree" },
      keymaps = {
        accept_suggestion = "<M-l>",
        clear_suggestion = "<M-e>",
        accept_word = "<M-h>",
      },
      color = {
        suggestion_color = get_comment_color(),
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
