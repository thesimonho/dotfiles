local M = {
	"m4xshen/smartcolumn.nvim",
	enabled = true,
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	require("smartcolumn").setup({
		colorcolumn = "120",
		custom_colorcolumn = { python = "88", rust = "100", javascript = "80", markdown = "80" },
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
			"lspinfo",
            "qf"
		},
		scope = "file",
	})
end

return M
