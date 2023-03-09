local M = {
	"lewis6991/gitsigns.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = { "BufReadPost, BufNewFile" },
}

function M.config()
	require("gitsigns").setup()
end

return M
