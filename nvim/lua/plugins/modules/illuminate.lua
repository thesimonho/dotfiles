-- Highlight occurences of the cursor word

local M = {
	"RRethy/vim-illuminate",
	cond = vim.g.vscode == nil,
	enabled = false,
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("illuminate").configure({
		delay = 50,
		under_cursor = false,
		min_count_to_highlight = 2,
		filetypes_denylist = {
			"neo-tree",
			"aerial",
		},
	})
	vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
	vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
	vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
end

return M
