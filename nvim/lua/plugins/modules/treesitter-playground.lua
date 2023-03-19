local M = {
	"nvim-treesitter/playground",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = "nvim-treesitter/nvim-treesitter",
	cmd = "TSPlaygroundToggle",
}

return M
