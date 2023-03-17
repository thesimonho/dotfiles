local M = {
	"anuvyklack/hydra.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = "VimEnter",
}

return M
