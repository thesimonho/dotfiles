local M = {
	"lukas-reineke/indent-blankline.nvim",
	enabled = true,
    cond = vim.g.vscode == nil,
	main = "ibl",
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	require("ibl").setup({
		indent = {
			char = "│",
			smart_indent_cap = true,
		},
		scope = {
			enabled = true,
			show_start = true,
			show_end = false,
		},
	})
end

return M
