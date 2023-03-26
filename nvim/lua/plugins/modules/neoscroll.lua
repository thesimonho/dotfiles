local M = {
	"karb94/neoscroll.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = "VeryLazy",
}

function M.config()
	require("neoscroll").setup({
		mappings = { "<C-u>", "<C-d>", "<C-f>", "<C-e>", "zt", "zz", "zb" },
		hide_cursor = true, -- Hide cursor while scrolling
		stop_eof = false, -- Stop at <EOF> when scrolling downwards
		respect_scrolloff = true, -- Stop scrolling when the cursor reaches the scrolloff margin of the file
		cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
		easing_function = nil, -- Default easing function
		performance_mode = false, -- Disable "Performance Mode" on all buffers.
	})
end

return M
