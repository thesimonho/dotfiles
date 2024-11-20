local headers = require("config.headers")
local quotes = require("config.quotes")
local header_list = { headers.cool, headers.vim, headers.panda, headers.snorlax, headers.undertale }
local quote_list = { quotes.roar, quotes.path, quotes.fear, quotes.gd }

math.randomseed(os.time())

local function format_tbl_text(text)
  return table.concat(text, "\n")
end

local M = {
  {
    "folke/snacks.nvim",
    opts = {
      styles = {
        dashboard = {
          wo = {
            foldcolumn = "0",
          },
        },
      },
      dashboard = {
        pane_gap = 20,
        preset = {
          keys = {
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = "󰟾 ", key = "m", desc = "Mason", action = ":Mason" },
          },
        },
        sections = {
          {
            text = { format_tbl_text(header_list[math.random(#header_list)]), hl = "String" },
            align = "center",
            padding = 2,
          },
          { section = "startup", padding = 1 },
          { section = "keys", padding = 4 },
          {
            text = { "  " .. format_tbl_text(quote_list[math.random(#quote_list)]), hl = "Comment" },
            align = "right",
          },
          { pane = 2, header = "Recent", padding = 2 },
          {
            pane = 2,
            icon = " ",
            title = "Files",
            section = "recent_files",
            limit = 10,
            indent = 3,
            padding = 2,
          },
          { pane = 2, icon = " ", title = "Projects", section = "projects", limit = 10, indent = 3, padding = 2 },
        },
        formats = {
          key = function(item)
            return { { "[", hl = "Special" }, { item.key, hl = "WindowPickerStatusLine" }, { "]", hl = "Special" } }
          end,
        },
      },
    },
  },
}

return M
