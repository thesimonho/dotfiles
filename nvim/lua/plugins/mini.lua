return {
  {
    "echasnovski/mini.bufremove",
    event = "LazyFile",
    keys = {
      { "<leader>bD", vim.NIL },
    },
  },
  {
    "echasnovski/mini.splitjoin",
    event = "LazyFile",
    keys = {
      { "<leader>cj", "<cmd>lua require('mini.splitjoin').toggle()<cr>", desc = "Split/join" },
    },
  },
}
