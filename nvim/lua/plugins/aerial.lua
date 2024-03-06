return {
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen", "AerialOpenAll" },
  keys = {
    { "<leader>cs", vim.NIL },
    { "<leader>co", "<cmd>AerialToggle<cr>", desc = "Aerial (Symbols)" },
  },
}
