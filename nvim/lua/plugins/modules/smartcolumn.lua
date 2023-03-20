local M = {
	"m4xshen/smartcolumn.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	require("smartcolumn").setup({
		colorcolumn = "120",
		custom_colorcolumn = { python = "79", rust = "100", javascript = "80", markdown = "80" },
		disabled_filetypes = {
			"help",
			"text",
			"lazy",
			"mason",
			"neo-tree",
			"NvimTree",
			"aerial",
			"Trouble",
			"OverseerList",
		},
		scope = "file",
	})
end

return M
