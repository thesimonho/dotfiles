local M = {
	"lewis6991/gitsigns.nvim",
	enabled = false,
    cond = vim.g.vscode == nil,
	event = { "BufReadPost, BufNewFile" },
}

function M.config()
	require("gitsigns").setup()
end

return M
