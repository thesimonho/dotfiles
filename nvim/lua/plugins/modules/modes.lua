local M = {
	"mvllow/modes.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	local colours = require("colours")
	require("modes").setup({
		colors = {
			copy = colours.normal,
			delete = colours.replace,
			insert = colours.insert,
			visual = colours.visual,
		},

		-- Set opacity for cursorline and number background
		line_opacity = 0.20,

		-- Enable cursor highlights
		set_cursor = true,

		-- Enable cursorline initially, and disable cursorline for inactive windows
		-- or ignored filetypes
		set_cursorline = true,

		-- Enable line number highlights to match cursorline
		set_number = true,

		-- Disable modes highlights in specified filetypes
		ignore_filetypes = { "neo-tree", "aerial", "OverseerList", "TelescopePrompt" },
	})
end

return M
