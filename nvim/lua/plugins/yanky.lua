return {
  "gbprod/yanky.nvim",
  keys = {
    { "<leader>p", vim.NIL },
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
  },
}
