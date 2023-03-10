local M = {
	"mrjones2014/nvim-ts-rainbow",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = "nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
}

return M
