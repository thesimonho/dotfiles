local M = {
	"Wansmer/treesj",
	enabled = true,
	dependencies = "nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("treesj").setup({
		use_default_keymaps = false,

		-- Node with syntax error will not be formatted
		check_syntax_error = true,

		-- If line after join will be longer than max value,
		-- node will not be formatted
		max_join_length = 320,

		-- hold - cursor follows the node/place on which it was called
		-- start - cursor jumps to the first symbol of the node being formatted
		-- end - cursor jumps to the last symbol of the node being formatted
		cursor_behavior = "hold",

		-- Notify about possible problems or not
		notify = true,
		dot_repeat = true,
	})
end

return M
