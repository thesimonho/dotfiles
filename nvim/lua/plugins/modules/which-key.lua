local M = {
	"folke/which-key.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	event = "VeryLazy",
}

function M.config()
	vim.opt.timeoutlen = 300

	local wk = require("which-key")
	wk.setup({
		defaults = {
			color_devicons = true,
		},
		show_help = false,
		window = {
			border = "none",
			margin = { 2, 50, 2, 50 },
			winblend = 5,
		},
		icons = {
			group = "…",
		},
	})

	wk.register({
		w = { name = "Window" },
	}, { prefix = "<leader>" })

	wk.register({
		b = { name = "Buffer" },
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

	wk.register({
		j = { name = "Jupyter" },
	}, { prefix = "<leader>" })

	wk.register({
		q = { name = "Quit", q = { name = "Quit all" } },
	}, { prefix = "<leader>" })
end

return M
