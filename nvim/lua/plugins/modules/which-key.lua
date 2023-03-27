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
		plugins = {
			marks = false, -- shows a list of your marks on ' and `
			registers = false, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
			-- the presets plugin, adds help for a bunch of default keybindings in Neovim
			spelling = {
				enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
				suggestions = 20, -- how many suggestions should be shown in the list?
			},
			presets = {
				operators = true, -- adds help for operators like d, y, ...
				motions = true, -- adds help for motions
				text_objects = true, -- help for text objects triggered after entering an operator
				windows = true, -- default bindings on <c-w>
				nav = true, -- misc bindings to work with windows
				z = true, -- bindings for folds, spelling and others prefixed with z
				g = true, -- bindings for prefixed with g
			},
		},
		defaults = {
			color_devicons = true,
		},
		show_help = false,
		window = {
			-- border = "single",
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
