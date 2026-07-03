-----------------------------------------------------------------------------
--- Kanagawa Paper Canvas
--- Upstream: https://github.com/thesimonho/kanagawa-paper.nvim/master/extras/wezterm_tabline/kanagawa-paper-canvas.lua
--- URL: https://github.com/michaelbrusegard/tabline.wez
-----------------------------------------------------------------------------

local M = {}

M = {
  normal_mode = {
    a = { fg = "#ecece8", bg = "#6b7a95" },
    b = { fg = "#6b7a95", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  copy_mode = {
    a = { fg = "#ecece8", bg = "#a56461" },
    b = { fg = "#a56461", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  search_mode = {
    a = { fg = "#ecece8", bg = "#866b81" },
    b = { fg = "#866b81", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  window_mode = {
    a = { fg = "#ecece8", bg = "#6b7a95" },
    b = { fg = "#6b7a95", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  resize_mode = {
    a = { fg = "#ecece8", bg = "#977865" },
    b = { fg = "#977865", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  tab_mode = {
    a = { fg = "#ecece8", bg = "#697f79" },
    b = { fg = "#697f79", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  default_mode = {
    a = { fg = "#ecece8", bg = "#a56461" },
    b = { fg = "#a56461", bg = "#ecece8" },
    c = { fg = "#79756d", bg = "#d1cfc5" },
  },
  tab = {
    active = { fg = '#6b7a95', bg = '#e1e1de', bold = true },
    inactive = { fg = '#79756d', bg = '#d1cfc5' },
    inactive_hover = { fg = '#866b81', bg = '#e1e1de' },
  },
  ansi = {
    "#79756d",
    "#a56461",
    "#697f79",
    "#8e7f5a",
    "#6d848e",
    "#866b81",
    "#6b7a95",
    "#94948d",
  },
  brights = {
    "#868279",
    "#b66f6c",
    "#748c85",
    "#9b8b63",
    "#829da8",
    "#95778f",
    "#7687a4",
    "#9e9e97",
  },
}

return M
