local constants = require("config.constants")
local fs = require("utils.fs")

return {
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xL", vim.NIL },
      { "<leader>xQ", vim.NIL },
      { "<leader>cS", vim.NIL },
    },
    opts = {
      focus = true, -- Focus the window when opened
      follow = true, -- Follow the current item
      indent_guides = true, -- show indent guides
      modes = {
        symbols = {
          focus = true,
          groups = {
            { "filename", format = "{file_icon}{short_filename} {count}" },
          },
          format = "{kind_icon}{symbol.name} {pos}",
          win = { position = "right", size = 35 },
        },
      },
      formatters = {
        short_filename = function(ctx)
          return { text = fs.shorten_path(ctx.item.dirname, 1) .. fs.get_path_sep() .. ctx.item.basename }
        end,
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<leader>sT", vim.NIL },
      { "<leader>xT", vim.NIL },
    },
  },
  {
    "stevearc/quicker.nvim",
    lazy = true,
    ft = "qf",
    opts = {
      opts = {
        number = false,
        relativenumber = false,
        winfixheight = true,
        wrap = false,
      },
      keys = {
        {
          "<Tab>",
          function()
            require("quicker").toggle_expand()
          end,
          desc = "Toggle context",
        },
        {
          "r",
          function()
            require("quicker").refresh()
          end,
          desc = "Refresh list",
        },
      },
      edit = {
        enabled = true,
        autosave = "unmodified",
      },
      highlight = {
        treesitter = true,
        lsp = true,
      },
      follow = {
        enabled = true,
      },
      type_icons = {
        E = constants.icons.diagnostics.Error,
        W = constants.icons.diagnostics.Warn,
        I = constants.icons.diagnostics.Info,
        N = constants.icons.diagnostics.Info,
        H = constants.icons.diagnostics.Hint,
      },
      borders = {
        vert = "│",
        -- Strong headers separate results from different files
        strong_header = "─",
        strong_cross = "┼",
        strong_end = "┤",
        -- Soft headers separate results within the same file
        soft_header = "╌",
        soft_cross = "┼",
        soft_end = "┤",
      },
      trim_leading_whitespace = "common",
    },
  },
}
