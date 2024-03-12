-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Delete some default keymaps
vim.api.nvim_del_keymap("n", "<leader>L")
vim.api.nvim_del_keymap("n", "<leader>-")
vim.api.nvim_del_keymap("n", "<leader>|")
vim.api.nvim_del_keymap("n", "<leader>w|")
vim.api.nvim_del_keymap("n", "<leader>xl")
vim.api.nvim_del_keymap("n", "<leader>xq")
vim.api.nvim_del_keymap("n", "<leader>`")
vim.api.nvim_del_keymap("n", "<leader>l")
vim.api.nvim_del_keymap("n", "<leader>ft")
vim.api.nvim_del_keymap("n", "<leader>fT")

-- Custom keymaps
vim.keymap.set("n", "<leader>zl", "<cmd>Lazy<cr>", { desc = "Lazy" })
vim.keymap.set("n", "<leader>zm", "<cmd>Mason<cr>", { desc = "Mason" })
vim.keymap.set("n", "<leader>zh", "<cmd>LazyHealth<cr>", { desc = "Health" })
vim.keymap.set("n", "<leader>zs", "<cmd>StartupTime<cr>", { desc = "StartupTime" })
vim.keymap.set("i", "<C-BS>", "<C-W>", { desc = "Delete word backward" }) -- Delete word backwards; some terminals: C-H = C-BS
vim.keymap.set("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forward" }) -- Delete word forwards
vim.keymap.set({ "n", "x" }, "gg", "mggg")
vim.keymap.set({ "n", "x" }, "G", "mgG")
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr><esc>", { desc = "Save file" })
vim.keymap.set("n", "<leader>w\\", "<C-W>v", { desc = "Split window right" })
vim.keymap.set("n", "<leader>wD", "<C-W>o", { desc = "Delete other windows" })
vim.keymap.set("n", "<leader>`", "<cmd>terminal nu<CR>", { desc = "Terminal" })

if vim.g.neovide then
  vim.keymap.set("v", "<C-c>", '"+y') -- Copy
  vim.keymap.set("n", "<C-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<C-v>", '"+P') -- Paste visual mode
  vim.keymap.set("i", "<C-v>", "<c-r>+") -- Paste insert mode
end
