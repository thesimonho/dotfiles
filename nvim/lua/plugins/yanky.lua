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
    { "<C-c>", "<Plug>(YankyYank)", mode = { "v" }, desc = "Yank Text" },

    { "P", "<Plug>(YankyPutBeforeLinewise)", mode = { "n", "x" }, desc = "Put before" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
    { "<C-v>", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
    { "<C-v>", "<C-r>+", mode = { "i" }, desc = "Put after" },
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
    ring = {
      sync_with_numbered_registers = true,
      update_register_on_cycle = true,
    },
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 200,
    },
    system_clipboard = {
      sync_with_ring = true,
      clipboard_register = "unnamedplus",
    },
    preserve_cursor_position = {
      enabled = true,
    },
    textobj = {
      enabled = true,
    },
  },
}
