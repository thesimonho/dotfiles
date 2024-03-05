-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.list = false

-- GUI options

vim.o.guifont = "FiraCode Nerd Font:h11"

if vim.g.neovide then
  vim.g.neovide_transparency = 0.96
  vim.keymap.set("v", "<C-c>", '"+y') -- Copy
  vim.keymap.set("n", "<C-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<C-v>", '"+P') -- Paste visual mode
end
