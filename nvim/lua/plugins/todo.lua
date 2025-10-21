local constants = require("config/constants")

-- TODO: text
-- FIXME: text
-- PERF: text
-- HACK: text
-- NOTE: text
-- WARN: text
-- TEST: text

return {
  "folke/todo-comments.nvim",
  opts = {
    signs = true,
    highlight = {
      keyword = "wide_bg", -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty.
      exclude = {},
    },
    keywords = (function()
      local keywords = {}
      for key, def in pairs(constants.todo_keywords) do
        -- shallow copy to avoid mutating the constants table
        keywords[key] = vim.tbl_deep_extend("force", {}, def, { color = key })
      end
      return keywords
    end)(),
    colors = (function()
      local colors = {}
      for key, def in pairs(constants.todo_keywords) do
        colors[key] = { def.highlight }
      end
      return colors
    end)(),
  },
}
