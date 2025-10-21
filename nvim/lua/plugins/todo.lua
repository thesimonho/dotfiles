-- TODO: text
-- FIXME: text
-- HACK: text
-- PERF: text
-- NOTE: text
-- WARN: text
-- TEST: text

return {
  "folke/todo-comments.nvim",
  opts = {
    signs = true,
    keywords = {
      FIX = {
        icon = "󱙒", -- icon used for the sign, and in search results
        color = "error", -- can be a hex color, or a named color (see below)
        alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
      },
      TODO = { icon = "󰎛", color = "info" },
      HACK = { icon = "󱝾", color = "warning" },
      WARN = { icon = "󱝾", color = "warning", alt = { "WARNING", "XXX" } },
      PERF = { icon = "", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = "󱞂", color = "hint", alt = { "INFO" } },
      TEST = { icon = "⏲", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
    },
    highlight = {
      -- * before: highlights before the keyword (typically comment characters)
      before = "", -- "fg" or "bg" or empty
      -- * keyword: highlights of the keyword
      keyword = "wide", -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
      -- * after: highlights after the keyword (todo text)
      after = "fg", -- "fg" or "bg" or empty
      pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns, used for highlighting (vim regex)
      exclude = {}, -- list of file types to exclude highlighting
    },
    search = {
      -- regex that will be used to match keywords.
      -- don't replace the (KEYWORDS) placeholder
      pattern = [[\b(KEYWORDS):]], -- ripgrep regex
    },
  },
}
