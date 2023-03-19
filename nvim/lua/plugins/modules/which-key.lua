local M = {
	"folke/which-key.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = "VeryLazy",
}

function M.config()
	vim.opt.timeoutlen = 100

	local wk = require("which-key")
	wk.setup({
		defaults = {
			color_devicons = true,
		},
		show_help = false,
		window = {
			border = "none",
			margin = { 2, 30, 2, 30 },
			winblend = 5,
		},
		icons = {
			group = "…",
		},
	})

	wk.register({
		v = { name = "Incremental select" },
	}, { prefix = "<leader>" })

	wk.register({
		f = { name = "Find" },
	}, { prefix = "<leader>" })

	wk.register({
		c = { name = "Code" },
	}, { prefix = "<leader>" })

	wk.register({
		g = { name = "Go to" },
	}, { prefix = "<leader>" })

	wk.register({
		r = { name = "Refactor", p = { name = "Print" } },
	}, { prefix = "<leader>" })
end

return M
