-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
local os = require("utils.os")

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.ai_cmp = false -- show suggestions in cmp

vim.opt.list = false
vim.opt.cursorline = true
vim.opt.shortmess:append("astWIF")
vim.opt.title = true
vim.opt.titlelen = 0 -- do not shorten title
vim.opt.titlestring = 'neovim -- %{expand("%:p:t")}'
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.pumblend = 10
vim.opt.sessionoptions = { "buffers", "folds", "winsize", "terminal" }

vim.opt.cursorcolumn = false
vim.opt.foldenable = true
vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.mousemoveevent = true

-- GUI options
if os.is_darwin() then
  vim.o.guifont = "FiraCode Nerd Font:h14"
else
  vim.o.guifont = "FiraCode Nerd Font:h11"
end

if vim.g.neovide then
  vim.g.neovide_transparency = 0.95
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.5
  vim.g.neovide_cursor_animate_in_insert_mode = false
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
end
