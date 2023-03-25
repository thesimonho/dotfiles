-- dim unused variables
local M = {
	"zbirenbaum/neodim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = "LspAttach",
}

function M.config()
	require("neodim").setup({
		alpha = 0.4,
		blend_color = require("colours").overlay,
		update_in_insert = {
			enable = true,
			delay = 100,
		},
		hide = {
			virtual_text = true,
			signs = true,
			underline = true,
		},
	})
end

return M
