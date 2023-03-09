local M = {
	"anuvyklack/windows.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = { "anuvyklack/middleclass", "anuvyklack/animation.nvim" },
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	vim.o.winwidth = 20
	vim.o.winminwidth = 20
	vim.o.equalalways = false
	require("windows").setup({
		autowidth = {
			enable = true,
		},
		ignore = {
			buftype = { "quickfix" },
			filetype = { "aerial", "neo-tree", "OverseerList" },
		},
		animation = {
			enable = true,
			duration = 200,
			fps = 60,
		},
	})
end

return M
