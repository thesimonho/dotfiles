local M = {
	"roobert/search-replace.nvim",
	enabled = false,
	cmd = {
		"SearchReplaceSingleBufferCWord",
		"SearchReplaceSingleBufferVisualSelection",
	},
}

function M.config()
	require("search-replace").setup({
		default_replace_single_buffer_options = "gc",
		default_replace_multi_buffer_options = "egc",
	})
end

return M
