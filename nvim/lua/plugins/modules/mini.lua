local M = {
	"echasnovski/mini.nvim",
	version = false,
	enabled = true,
	lazy = false,
}

function M.config()
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
