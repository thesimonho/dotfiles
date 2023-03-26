local M = {
	"nvim-telescope/telescope.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"nvim-telescope/telescope-project.nvim",
		"nvim-telescope/telescope-file-browser.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	cmd = "Telescope",
}

function M.config()
	local actions = require("telescope.actions")
	local project_actions = require("telescope._extensions.project.actions")
	local fb_actions = require("telescope._extensions.file_browser.actions")

	require("telescope").setup({
		defaults = {
			sorting_strategy = "ascending",
			scroll_strategy = "limit",
			layout_strategy = "horizontal",
			layout_config = { width = 0.8, prompt_position = "top" },
			borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
			wrap_results = false,
			dynamic_preview_title = true,
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
			project = {
				base_dirs = {
					"F:\\",
				},
				hidden_files = false,
				theme = "dropdown",
				order_by = "recent",
				search_by = "title",
				on_project_selected = function(prompt_bufnr)
					project_actions.change_working_directory(prompt_bufnr)
					-- project_actions.find_project_files(prompt_bufnr, false)
				end,
			},
			file_browser = {
				cwd_to_path = false,
				grouped = true,
				files = true,
				add_dirs = true,
				depth = 1,
				auto_depth = false,
				select_buffer = false,
				hidden = false,
				hide_parent_dir = false,
				collapse_dirs = false,
				prompt_path = false,
				quiet = false,
				display_stat = { date = true, size = true, mode = true },
				hijack_netrw = false,
				use_fd = true,
				git_status = true,
				mappings = {
					["i"] = {
						["<Tab>"] = fb_actions.toggle_browser,
					},
					["n"] = {
						["<Tab>"] = fb_actions.toggle_browser,
					},
				},
			},
		},
	})
	require("telescope").load_extension("noice")
	require("telescope").load_extension("file_browser")
end

return M
