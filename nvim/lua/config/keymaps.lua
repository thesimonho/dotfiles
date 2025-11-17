-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local wk = require("which-key")

-- Delete some default keymaps
vim.api.nvim_del_keymap("n", "<leader>K")
vim.api.nvim_del_keymap("n", "<leader>L")
vim.api.nvim_del_keymap("n", "<leader>-")
vim.api.nvim_del_keymap("n", "<leader>|")
vim.api.nvim_del_keymap("n", "<leader>/")
vim.api.nvim_del_keymap("n", "<C-w><C-D>")
vim.api.nvim_del_keymap("n", "<leader>bb")
vim.api.nvim_del_keymap("n", "<leader>bo")
vim.api.nvim_del_keymap("n", "<leader>l")
vim.api.nvim_del_keymap("n", "<leader>fb")
vim.api.nvim_del_keymap("n", "<leader>fB")
vim.api.nvim_del_keymap("n", "<leader>ft")
vim.api.nvim_del_keymap("n", "<leader>fT")
vim.api.nvim_del_keymap("n", "<leader>fg")
vim.api.nvim_del_keymap("n", "<leader>fF")
vim.api.nvim_del_keymap("n", "<leader>gf")
vim.api.nvim_del_keymap("n", "<leader>gG")
vim.api.nvim_del_keymap("n", "<leader>gL")
vim.api.nvim_del_keymap("n", "<leader>sG")
vim.api.nvim_del_keymap("n", "<leader>sW")
vim.api.nvim_del_keymap("n", "<leader><tab>o")

-- General
vim.keymap.set("i", "kj", "<esc>")
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit" })
vim.keymap.set("v", "<C-c>", '"+y') -- Copy
vim.keymap.set("i", "<C-v>", '<esc>"+pa') -- Paste
vim.keymap.set("i", "<C-Del>", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  -- If at the end of the line, delete to the start of the next line
  if col > #line then
    return vim.api.nvim_replace_termcodes("<C-o>J", true, true, true)
  else
    return vim.api.nvim_replace_termcodes("<C-o>dw", true, true, true)
  end
end, { expr = true, desc = "Delete word forward" })
vim.keymap.set({ "n", "x" }, "gg", "mggg", { desc = "Go to top of file" })
vim.keymap.set({ "n", "x" }, "G", "mgG", { desc = "Go to bottom of file" })
vim.keymap.set("v", "A", "<Esc>ggVG$", { desc = "Select all" })
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr><esc>", { desc = "Save File" })
vim.keymap.set("n", "q", "<nop>", { noremap = true }) -- unmap q because its too easy to hit by accident
vim.keymap.set("n", "Q", "q", { noremap = true, desc = "Record macro" })
vim.keymap.set("n", "<M-q>", "Q", { noremap = true, desc = "Replay last register" })

-- Windows
vim.keymap.set("n", "<leader>wD", "<C-W>o", { desc = "Delete other windows" })
vim.keymap.set("n", "<leader>wo", "<C-W>p", { desc = "Other window" })

-- Tabs
vim.keymap.set("n", "<leader><tab>n", "<cmd>tabedit<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader><tab>D", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })

-- Terminals
vim.keymap.set({ "t", "i" }, "<esc>", "<C-\\><C-n>", { silent = true })
vim.keymap.set({ "t", "i" }, "<C-h>", "<C-\\><C-n><C-w>h", { silent = true })
vim.keymap.set({ "t", "i" }, "<C-j>", "<C-\\><C-n><C-w>j", { silent = true })
vim.keymap.set({ "t", "i" }, "<C-k>", "<C-\\><C-n><C-w>k", { silent = true })
vim.keymap.set({ "t", "i" }, "<C-l>", "<C-\\><C-n><C-w>l", { silent = true })

-- Tools
wk.add({ "<leader>z", group = "tools", icon = "" })
vim.keymap.set("n", "<leader>zl", "<cmd>Lazy<cr>", { desc = "Lazy" })
vim.keymap.set("n", "<leader>zm", "<cmd>Mason<cr>", { desc = "Mason" })
vim.keymap.set("n", "<leader>zh", "<cmd>LazyHealth<cr>", { desc = "Health" })
vim.keymap.set("n", "<leader>zL", "<cmd>LspInfo<cr>", { desc = "LspInfo" })
vim.keymap.set("n", "<leader>zr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
vim.keymap.set("n", "<leader>zc", "<cmd>CccPick<cr>", { desc = "Color Picker" })
