-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete some default keymaps
vim.api.nvim_del_keymap("n", "<leader>L")
vim.api.nvim_del_keymap("n", "<leader>-")
vim.api.nvim_del_keymap("n", "<leader>|")

-- Custom keymaps
vim.keymap.set("i", "<C-H>", "<C-W>", { desc = "Delete word backward" }) -- Delete word backwards; C-H = C-BS
vim.keymap.set("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forward" }) -- Delete word forwards
vim.keymap.set({ "n", "x" }, "gg", "mggg")
vim.keymap.set({ "n", "x" }, "G", "mgG")
