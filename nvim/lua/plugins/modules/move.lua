local M = {
	"booperlv/nvim-gomove",
	enabled = true,
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("gomove").setup({
		-- whether or not to map default key bindings, (true/false)
		map_defaults = false,
		-- whether or not to reindent lines moved vertically (true/false)
		reindent = true,
		-- whether or not to undojoin same direction moves (true/false)
		undojoin = true,
		-- whether to not to move past end column when moving blocks horizontally, (true/false)
		move_past_end_col = false,
	})
end

return M
