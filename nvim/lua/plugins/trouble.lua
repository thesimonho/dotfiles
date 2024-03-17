M = {
  "folke/trouble.nvim",
  keys = {
    { "<leader>xQ", vim.NIL },
    { "<leader>xL", vim.NIL },
    { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
    { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
  },
}

-- linked groups for all themes
vim.api.nvim_set_hl(0, "TroubleCount", { link = "DiagnosticOk" })
vim.api.nvim_set_hl(0, "TroubleTextHint", { link = "DiagnosticHint" })
vim.api.nvim_set_hl(0, "TroubleTextError", { link = "DiagnosticError" })
vim.api.nvim_set_hl(0, "TroubleTextWarning", { link = "DiagnosticWarn" })
vim.api.nvim_set_hl(0, "TroubleTextInformation", { link = "DiagnosticInfo" })

return M
