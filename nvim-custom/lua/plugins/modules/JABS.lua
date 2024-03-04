local M = {
	"matbme/JABS.nvim",
	enabled = true,
    cond = vim.g.vscode == nil,
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("jabs").setup({
		-- Options for the main window
		position = { "left", "bottom" }, -- position = {'<position_x>', '<position_y>'} | <position_x> left, center, right,
		relative = "win", -- win, editor, cursor. Default win

		width = 50, -- default 50
		height = 10, -- default 10
		border = "none", -- none, single, double, rounded, solid, shadow, (or an array or chars). Default shadow

		offset = { -- window position offset
			top = 2, -- default 0
			bottom = 2, -- default 0
			left = 2, -- default 0
			right = 2, -- default 0
		},

		sort_mru = true, -- Sort buffers by most recently used (true or false). Default false
		split_filename = true, -- Split filename into separate components for name and path. Default false
		split_filename_path_width = 20, -- If split_filename is true, how wide the column for the path is supposed to be, Default 0 (don't show path)

		-- Options for preview window
		preview_position = "top", -- top, bottom, left, right. Default top
		preview = {
			width = 70, -- default 70
			height = 30, -- default 30
			border = "single", -- none, single, double, rounded, solid, shadow, (or an array or chars). Default double
		},

		-- Default highlights (must be a valid :highlight)
		highlight = {
			current = "Title", -- default StatusLine
			hidden = "StatusLineNC", -- default ModeMsg
			split = "WarningMsg", -- default StatusLine
			alternate = "StatusLine", -- default WarningMsg
		},

		-- Keymaps
		keymap = {
			close = "D", -- Close buffer. Default D
			preview = "p", -- Open buffer preview. Default P
		},

		-- Whether to use nvim-web-devicons next to filenames
		use_devicons = true, -- true or false. Default true
	})
end

return M
