local M = {
	"nvim-neotest/neotest",
	enabled = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"folke/neodev.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ChristianChiarulli/neovim-codicons",
		"nvim-neotest/neotest-python",
		"rouge8/neotest-rust",
	},
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("neotest").setup({
		adapters = {
			require("neotest-rust"),
			require("neotest-python")({
				runner = "pytest",
				python = "python",
				dap = { justMyCode = false },
			}),
		},
		consumers = {},
		default_strategy = "integrated",
		output = {
			enabled = true,
			open_on_run = "short",
		},
		output_panel = {
			enabled = true,
			open = "botright split | resize 15",
		},
		quickfix = {
			enabled = true,
			open = false,
		},
		run = {
			enabled = true,
		},
		running = {
			concurrent = true,
		},
		state = {
			enabled = true,
		},
		status = {
			enabled = true,
			signs = true,
			virtual_text = false,
		},
		summary = {
			animated = true,
			enabled = true,
			expand_errors = true,
			follow = true,
			mappings = {
				attach = "a",
				clear_marked = "M",
				clear_target = "T",
				debug = "d",
				debug_marked = "D",
				expand = { "<CR>", "<2-LeftMouse>" },
				expand_all = "e",
				jumpto = "i",
				mark = "m",
				next_failed = "J",
				output = "o",
				prev_failed = "K",
				run = "r",
				run_marked = "R",
				short = "O",
				stop = "u",
				target = "t",
			},
			open = "botright vsplit | vertical resize 50",
		},
	})
end

return M
