M = {
  "folke/todo-comments.nvim",
  keys = {
    { "<leader>st", vim.NIL },
    { "<leader>sT", vim.NIL },
    { "<leader>xt", vim.NIL },
    { "<leader>xT", vim.NIL },
    { "<leader>ct", "<cmd>TodoTrouble<cr>", desc = "TODO" },
  },
}

-- set default Todo HL to same as Comment (plugins can use their own HL group for Todo:)
vim.api.nvim_set_hl(0, "Todo", { link = "Comment" })

return M
