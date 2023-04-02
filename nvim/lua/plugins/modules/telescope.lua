local M = {
	"nvim-telescope/telescope.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"nvim-telescope/telescope-project.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	cmd = "Telescope",
}

function M.config()
	local actions = require("telescope.actions")
	local project_actions = require("telescope._extensions.project.actions")

	require("telescope").setup({
		defaults = {
			sorting_strategy = "ascending",
			scroll_strategy = "limit",
			layout_strategy = "horizontal",
			layout_config = { width = 0.8, prompt_position = "top" },
			borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
			path_display = { shorten = { len = 2, exclude = { -1, -2, -3 } } },
			wrap_results = false,
			dynamic_preview_title = true,
			file_ignore_patterns = {
				"node_modules",
			},
			mappings = {
				i = {
					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
					["<C-q>"] = function(bufnr)
						actions.smart_send_to_qflist(bufnr)
						vim.cmd("TroubleToggle quickfix")
					end,
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
			project = {
				base_dirs = {
					"~",
					"F:\\",
				},
				hidden_files = false,
				theme = "dropdown",
				order_by = "recent",
				search_by = "title",
				on_project_selected = function(prompt_bufnr)
					project_actions.find_project_files(prompt_bufnr, false)
					-- project_actions.change_working_directory(prompt_bufnr)
					-- vim.cmd("%bw!")
				end,
			},
		},
	})
	require("telescope").load_extension("noice")
end

return M
