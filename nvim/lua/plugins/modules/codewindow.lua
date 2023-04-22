local M = {
	"gorbit99/codewindow.nvim",
	enabled = true,
	event = { "BufReadPre", "BufNewFile" },
}

function M.config()
	local codewindow = require("codewindow")
	codewindow.setup({
		active_in_terminals = false, -- Should the minimap activate for terminal buffers
		auto_enable = true, -- Automatically open the minimap when entering a (non-excluded) buffer
		exclude_filetypes = {
			"alpha",
			"neo-tree",
			"aerial",
			"OverseerList",
			"Trouble",
			"dapui_scopes",
			"dapui_breakpoints",
			"dapui_stacks",
			"dapui_watches",
			"dap-repl",
		},
		max_minimap_height = nil, -- The maximum height the minimap can take (including borders)
		max_lines = nil, -- If auto_enable is true, don't open the minimap for buffers which have too many lines.
		minimap_width = 10, -- The width of the text part of the minimap
		use_treesitter = true, -- Use nvim-treesitter to highlight the code
		use_lsp = true, -- Use the builtin LSP to show errors and warnings
		use_git = true, -- Show small dots to indicate git additions and deletions
		width_multiplier = 5, -- How many characters one dot represents
		z_index = 1, -- The z-index the floating window will be on
		show_cursor = true, -- Show the cursor position in the minimap
		window_border = "single", -- The border style of the floating window (accepts all usual options)
		events = { "TextChanged", "InsertLeave", "DiagnosticChanged", "FileWritePost", "BufEnter" },
	})
end

return M
