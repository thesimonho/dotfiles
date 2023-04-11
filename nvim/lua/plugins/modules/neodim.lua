-- dim unused variables
local M = {
	"zbirenbaum/neodim",
	enabled = true,
	event = "LspAttach",
}

function M.config()
	require("neodim").setup({
		alpha = 0.5,
		blend_color = require("colours").bg,
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
