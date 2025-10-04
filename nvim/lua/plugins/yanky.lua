return {
  "gbprod/yanky.nvim",
  keys = {
    { "<leader>p", vim.NIL },
    { "<leader>y", "<cmd>YankyRingHistory<cr>", desc = "Yank History" },
    { "p", "<Plug>(YankyPutIndentAfterCharwise)", desc = "Put after" },
    { "P", "<Plug>(YankyPutBeforeLinewise)", desc = "Put before" },
    {
      "iy",
      function()
        require("yanky.textobj").last_put()
      end,
      mode = { "o", "x" },
      desc = "yank",
    },
    {
      "ay",
      function()
        require("yanky.textobj").last_put()
      end,
      mode = { "o", "x" },
      desc = "yank",
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
    textobj = {
      enabled = true,
    },
  },
}
