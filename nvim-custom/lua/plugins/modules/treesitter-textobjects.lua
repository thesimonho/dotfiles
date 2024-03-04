local M = {
	"nvim-treesitter/nvim-treesitter-textobjects",
	enabled = true,
    cond = vim.g.vscode == nil,
	dependencies = "nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
}

return M
