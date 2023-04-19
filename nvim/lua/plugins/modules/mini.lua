local M = {
	"echasnovski/mini.nvim",
	version = false,
	enabled = true,
	lazy = false,
}

function M.config()
    -- TODO: replace this with something that provides more control
	local map = require("mini.map")
	map.setup({
		integrations = {
			map.gen_integration.builtin_search(),
			map.gen_integration.diagnostic(),
			map.gen_integration.gitsigns(),
		},

		symbols = {
			encode = map.gen_encode_symbols.dot("3x2"),
			scroll_line = "▶ ",
			scroll_view = "┃",
		},

		window = {
			focusable = true,
			side = "right",
			show_integration_count = false,
			width = 10,
			winblend = 50,
		},
	})

	require("mini.splitjoin").setup({
		mappings = {
			toggle = "",
			split = "",
			join = "",
		},
	})

	require("mini.comment").setup({
		options = {
			ignore_blank_line = true,

			-- Whether to recognize as comment only lines without indent
			start_of_line = false,

			-- Whether to ensure single space pad for comment parts
			pad_comment_parts = true,
		},
	})

	require("mini.move").setup()
	require("mini.pairs").setup()
	require("mini.cursorword").setup()
	require("mini.surround").setup({ silent = true })

	vim.cmd("hi! MiniCursorwordCurrent guifg=NONE guibg=NONE gui=NONE cterm=NONE")
end

return M
