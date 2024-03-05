return {
  "linux-cultist/venv-selector.nvim",
  cmd = "VenvSelect",
  ft = "python",
  keys = {
    { "<leader>cv", vim.NIL },
    { "<leader>zv", "<cmd>:VenvSelect<cr>", desc = "Python VirtualEnv" },
  },
}
