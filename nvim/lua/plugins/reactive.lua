Colours = require("config/colours")

return {
  "rasulomaroff/reactive.nvim",
  enabled = false,
  lazy = false,
  config = function()
    require("reactive").add_preset({
      name = "main",
      init = function()
        vim.opt.guicursor:append("a:ReactiveCursor")
      end,
      modes = {
        [{ "i", "niI" }] = {
          hl = {
            ReactiveCursor = { bg = Colours.insert },
            CursorLine = { bg = Colours.insertBG },
            CursorLineNr = { fg = Colours.insert },
          },
        },
        n = {
          hl = {
            ReactiveCursor = { bg = Colours.normal },
            CursorLine = { bg = Colours.cursorLine },
            CursorLineNr = { fg = Colours.normal },
          },
        },
        no = {
          operators = {
            d = {
              hl = {
                ReactiveCursor = { bg = Colours.replace },
                CursorLine = { bg = Colours.insertBG },
                CursorLineNr = { fg = Colours.replace },
              },
            },
            y = {
              hl = {
                ReactiveCursor = { bg = Colours.yank },
                CursorLineNr = { fg = Colours.yank },
              },
            },
            c = {
              hl = {
                ReactiveCursor = { bg = Colours.insert },
                CursorLine = { bg = Colours.insertBG },
                CursorLineNr = { fg = Colours.insert },
              },
            },
          },
        },
        [{ "v", "V", "\x16" }] = {
          hl = {
            ReactiveCursor = { bg = Colours.visual },
            CursorLineNr = { fg = Colours.visual },
          },
        },
        c = {
          hl = {
            ReactiveCursor = { bg = Colours.insert },
            CursorLine = { bg = Colours.insertBG },
            CursorLineNr = { fg = Colours.insert },
          },
        },
        [{ "s", "S", "\x13" }] = {
          hl = {
            ReactiveCursor = { bg = Colours.visual },
            CursorLineNr = { fg = Colours.visual },
          },
        },
        [{ "R", "niR", "niV" }] = {
          hl = {
            ReactiveCursor = { bg = Colours.replace },
            CursorLine = { bg = Colours.insertBG },
            CursorLineNr = { fg = Colours.replace },
          },
        },
      },
    })
  end,
}
