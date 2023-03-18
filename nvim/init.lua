vim.g.mapleader = " " -- set this before loading plugins

require("plugins")
require("keybinds")
require("autocommands")
require("settings")

if vim.g.vscode then
	require("keybinds_vscode")
else
	require("keybinds_nvim")
end
