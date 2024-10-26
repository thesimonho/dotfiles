return {
  "gbprod/yanky.nvim",
  keys = {
    { "<leader>p", vim.NIL },
    { "p", "<Plug>(YankyPutAfter)", desc = "Put after" },
    { "P", "<Plug>(YankyPutBeforeLinewise)", desc = "Put before" },
    {
      "<leader>y",
      function()
        require("telescope").extensions.yank_history.yank_history({})
      end,
      desc = "Yank History",
    },
  },
  opts = {
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 200,
    },
    preserve_cursor_position = {
      enabled = true,
    },
    picker = {
      telescope = {
        use_default_mappings = false,
        mappings = {
          i = {
            ["<CR>"] = require("yanky.telescope.mapping").put("p"),
            ["<C-d>"] = require("yanky.telescope.mapping").delete(),
          },
          n = {
            ["<CR>"] = require("yanky.telescope.mapping").put("p"),
            p = require("yanky.telescope.mapping").put("p"),
            P = require("yanky.telescope.mapping").put("P"),
            d = require("yanky.telescope.mapping").delete(),
          },
        },
      },
    },
  },
}
