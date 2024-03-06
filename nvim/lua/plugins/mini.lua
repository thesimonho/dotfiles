return {
  {
    "echasnovski/mini.bufremove",
    keys = {
      { "<leader>bD", vim.NIL },
    },
  },
  {
    "echasnovski/mini.indentscope",
    draw = {
      delay = 50,
      animation = require("mini.indentscope").gen_animation.quadratic({
        easing = "out",
        duration = 100,
        unit = "total",
      }),
    },
  },
}
