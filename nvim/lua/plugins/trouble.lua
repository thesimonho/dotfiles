return {
  "folke/trouble.nvim",
  keys = {
    { "<leader>xQ", vim.NIL },
    { "<leader>xL", vim.NIL },
    { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
    { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
  },
}
