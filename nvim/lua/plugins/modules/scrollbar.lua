local M = {
	"petertriho/nvim-scrollbar",
	enabled = true,
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	require("scrollbar").setup({
		show = true,
		show_in_active_only = true,
		set_highlights = true,
		hide_if_all_visible = true, -- Hides everything if all lines are visible
		throttle_ms = 100,
		handle = {
			highlight = "Scrollbar",
			hide_if_all_visible = true, -- Hides handle if all lines are visible
		},
		marks = {
			Cursor = {
				highlight = "ScrollbarCursor",
			},
		},
		excluded_buftypes = {
			"terminal",
		},
		excluded_filetypes = {
			"prompt",
			"TelescopePrompt",
			"noice",
			"neo-tree",
			"NvimTree",
			"aerial",
			"OverseerList",
		},
		handlers = {
			cursor = true,
			diagnostic = false,
			gitsigns = true, -- Requires gitsigns
			handle = true,
			search = false, -- Requires hlslens
			ale = false, -- Requires ALE
		},
	})
end

return M
