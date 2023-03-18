local M = {
	"mrjones2014/nvim-ts-rainbow",
	cond = vim.g.vscode == nil,
	enabled = false,
	dependencies = "nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
}

return M
