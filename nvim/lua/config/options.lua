-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.list = false
vim.opt.cursorline = true
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.lsp.set_log_level("off")

-- GUI options

vim.o.guifont = "FiraCode Nerd Font:h11"

if vim.g.neovide then
  vim.g.neovide_transparency = 0.95
  vim.g.neovide_cursor_animation_length = 0.1
  vim.g.neovide_cursor_trail_size = 0.8
end
