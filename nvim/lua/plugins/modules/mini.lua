local M = {
	"echasnovski/mini.nvim",
	version = false,
	enabled = true,
	event = "VeryLazy",
}

function M.config()
	local map = require("mini.map")
	map.setup({
		integrations = {
			map.gen_integration.builtin_search(),
			map.gen_integration.diagnostic(),
			map.gen_integration.gitsigns(),
		},

		symbols = {
			encode = map.gen_encode_symbols.dot("3x2"),
		},

		window = {
			focusable = true,
			side = "right",
			show_integration_count = false,
			width = 10,
			winblend = 25,
		},
	})

	require("mini.splitjoin").setup({
		mappings = {
			toggle = "",
			split = "",
			join = "",
		},
	})

	require("mini.move").setup()
	require("mini.cursorword").setup()
	require("mini.surround").setup({ silent = true })

	vim.cmd("hi! MiniCursorwordCurrent guifg=NONE guibg=NONE gui=NONE cterm=NONE")
end

return M
