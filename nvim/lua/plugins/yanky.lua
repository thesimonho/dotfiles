return {
  "gbprod/yanky.nvim",
  keys = {
    {
      "<leader>y",
      function()
        Snacks.picker.yanky()
      end,
      desc = "Yank History",
    },
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
    { "P", "<Plug>(YankyPutBeforeLinewise)", mode = { "n", "x" }, desc = "Put before" },
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
