local M = {
	"gbprod/yanky.nvim",
	enabled = true,
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	local utils = require("yanky.utils")
	local mapping = require("yanky.telescope.mapping")

	require("yanky").setup({
		highlight = {
			on_put = true,
			on_yank = true,
			timer = 200,
		},
		preserve_cursor_position = {
			enabled = true,
		},
		picker = {
			telescope = {
				mappings = {
					default = mapping.put("P"),
					i = {
						["<c-x>"] = mapping.delete(),
						["<c-r>"] = mapping.set_register(utils.get_default_register()),
					},
					n = {
						x = mapping.delete(),
						r = mapping.set_register(utils.get_default_register()),
					},
				},
			},
		},
	})
	require("telescope").load_extension("yank_history")
end

return M
