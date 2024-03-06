return {
  {
    "echasnovski/mini.bufremove",
    keys = {
      { "<leader>bD", vim.NIL },
    },
  },
  {
    "echasnovski/mini.indentscope",
    opts = {
      draw = {
        delay = 50,
        animation = require("mini.indentscope").gen_animation.quadratic({
          easing = "out",
          duration = 10,
          unit = "step",
        }),
      },
    },
  },
  {
    "echasnovski/mini.splitjoin",
    keys = {
      { "<leader>cj", "<cmd>lua require('mini.splitjoin').toggle()<cr>", desc = "Split/join" },
    },
  },
}
