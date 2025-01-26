return {
  "gbprod/yanky.nvim",
  keys = {
    { "<leader>p", vim.NIL },
    { "<leader>y", "<cmd>YankyRingHistory<cr>", desc = "Yank History" },
    { "p", "<Plug>(YankyPutAfter)", desc = "Put after" },
    { "P", "<Plug>(YankyPutBeforeLinewise)", desc = "Put before" },
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
  },
}
