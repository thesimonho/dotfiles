-----------------------------------------------------------------------------
--- Kanagawa Paper Ink
--- Upstream: https://github.com/thesimonho/kanagawa-paper.nvim/master/extras/wezterm_tabline/kanagawa-paper-ink.lua
--- URL: https://github.com/michaelbrusegard/tabline.wez
-----------------------------------------------------------------------------

local M = {}

M.theme_overrides = {
  normal_mode = {
    a = { fg = "#2A2A37", bg = "#c4b28a" },
    b = { fg = "#c4b28a", bg = "#2A2A37" },
    c = { fg = "#727169", bg = "#2A2A37" },
  },
  copy_mode = {
    a = { fg = "#2A2A37", bg = "#c4746e" },
    b = { fg = "#c4746e", bg = "#2A2A37" },
    c = { fg = "#727169", bg = "#2A2A37" },
  },
  search_mode = {
    a = { fg = "#2A2A37", bg = "#938AA9" },
    b = { fg = "#938AA9", bg = "#2A2A37" },
    c = { fg = "#727169", bg = "#2A2A37" },
  },
  window_mode = {
    a = { fg = "#2A2A37", bg = "#658594" },
    b = { fg = "#658594", bg = "#2A2A37" },
    c = { fg = "#727169", bg = "#2A2A37" },
  },
  resize_mode = {
    a = { fg = "#2A2A37", bg = "#b6927b" },
    b = { fg = "#b6927b", bg = "#2A2A37" },
    c = { fg = "#727169", bg = "#2A2A37" },
  },
}

return M
