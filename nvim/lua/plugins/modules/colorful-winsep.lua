local M = {
	"nvim-zh/colorful-winsep.nvim",
	cond = vim.g.vscode == nil,
	enabled = false,
	event = { "VeryLazy" },
}

function M.config()
	require("colorful-winsep").setup({
		highlight = { fg = require("colours").sep, bg = vim.api.nvim_get_hl_by_name("Normal", true)["background"] },
	})
end

return M
