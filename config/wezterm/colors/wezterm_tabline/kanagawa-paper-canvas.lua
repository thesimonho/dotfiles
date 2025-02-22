-----------------------------------------------------------------------------
--- Kanagawa Paper Canvas
--- Upstream: https://github.com/thesimonho/kanagawa-paper.nvim/master/extras/wezterm_tabline/kanagawa-paper-canvas.lua
--- URL: https://github.com/michaelbrusegard/tabline.wez
-----------------------------------------------------------------------------

local M = {}

M.theme_overrides = {
  normal_mode = {
    a = { fg = "#cbc8bc", bg = "#618bb6" },
    b = { fg = "#618bb6", bg = "#e9e9e0" },
    c = { fg = "#858479", bg = "#cbc8bc" },
  },
  copy_mode = {
    a = { fg = "#cbc8bc", bg = "#ba4e5a" },
    b = { fg = "#ba4e5a", bg = "#e9e9e0" },
    c = { fg = "#858479", bg = "#cbc8bc" },
  },
  search_mode = {
    a = { fg = "#cbc8bc", bg = "#5e56a1" },
    b = { fg = "#5e56a1", bg = "#e9e9e0" },
    c = { fg = "#858479", bg = "#cbc8bc" },
  },
  window_mode = {
    a = { fg = "#cbc8bc", bg = "#96b7d1" },
    b = { fg = "#96b7d1", bg = "#e9e9e0" },
    c = { fg = "#858479", bg = "#cbc8bc" },
  },
  resize_mode = {
    a = { fg = "#cbc8bc", bg = "#b8805e" },
    b = { fg = "#b8805e", bg = "#e9e9e0" },
    c = { fg = "#858479", bg = "#cbc8bc" },
  },
}

return M
