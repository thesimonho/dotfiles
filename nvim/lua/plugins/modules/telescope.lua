local M = {
	"nvim-telescope/telescope.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = {
		{
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},
	cmd = "Telescope",
}

function M.config()
	local actions = require("telescope.actions")
	require("telescope").setup({
		defaults = {
			layout_strategy = "horizontal",
			layout_config = { width = 0.8 },
			prompt_prefix = " 🔍 ",
			file_ignore_patterns = {
				"node_modules",
			},
			mappings = {
				i = {
					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
				},
			},
		},
		extensions = {
			fzf = {
				fuzzy = true, -- false will only do exact matching
				override_generic_sorter = true, -- override the generic sorter
				override_file_sorter = true, -- override the file sorter
				case_mode = "smart_case", -- or "ignore_case" or "respect_case"
			},
		},
	})
	require("telescope").load_extension("projects")
	require("telescope").load_extension("noice")
end

return M
