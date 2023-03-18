local M = {
	"m4xshen/smartcolumn.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	require("smartcolumn").setup({
		colorcolumn = "120",
		disabled_filetypes = { "help", "text", "markdown" },
		custom_colorcolumn = { python = "79", rust = "100", javascript = "80" },
		scope = "file",
	})
end

return M
