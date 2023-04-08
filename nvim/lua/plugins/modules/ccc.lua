local M = {
	"uga-rosa/ccc.nvim",
	enabled = true,
	cmd = "CccPick",
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	local mapping = require("ccc").mapping
	require("ccc").setup({
		default_color = "#40bfbf",
		highlighter = { auto_enable = true },
		save_on_quit = true,
		inputs = { require("ccc").input.hsl, require("ccc").input.rgb },
		recognize = { input = false, output = true },
		win_opts = {
			relative = "cursor",
			style = "minimal",
			border = "solid",
		},
		mappings = {
			["p"] = mapping.toggle_prev_colors,
		},
	})
end

return M
