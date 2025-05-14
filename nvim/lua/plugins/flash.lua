return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({ search = { forward = true } })
        end,
        desc = "Flash forward",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({ search = { forward = false } })
        end,
        desc = "Flash backward",
      },
      {
        "<M-s>",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
    opts = {
      search = {
        multi_window = false,
        incremental = true,
        forward = true,
        wrap = false,
      },
      jump = {
        nohlsearch = false,
      },
      label = {
        uppercase = false,
        before = false,
        after = true,
        style = "overlay",
        rainbow = {
          enabled = false,
        },
      },
      modes = {
        search = {
          enabled = true,
        },
        char = {
          enabled = false, -- operator pending mode doesnt work like normal vim & interferes with eyeliner
        },
      },
    },
  },
  {
    "jinh0/eyeliner.nvim",
    event = "LazyFile",
    opts = {
      -- show highlights only after keypress
      highlight_on_key = true,
      -- dim all other characters if set to true (recommended!)
      dim = true,
      default_keymaps = true,
    },
  },
}
