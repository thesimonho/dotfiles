local M = {
	"stevearc/dressing.nvim",
	enabled = true,
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
