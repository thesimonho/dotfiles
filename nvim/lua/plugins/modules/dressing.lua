local M = {
	"stevearc/dressing.nvim",
	enabled = false,
	event = "VeryLazy",
}

function M.config()
	require("dressing").setup({
		input = {
			enabled = false,
		},
	})
end

return M
