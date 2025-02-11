local fs = require("utils.fs")

return {
  {
    "folke/trouble.nvim",
    init = function()
      local wk = require("which-key")
      wk.add({ "<leader>cS", name = "LSP references (Trouble)" })
    end,
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
}
