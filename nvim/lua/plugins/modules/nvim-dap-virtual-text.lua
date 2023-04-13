local M = {
	"theHamsta/nvim-dap-virtual-text",
	enabled = true,
	dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("nvim-dap-virtual-text").setup({
		highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
		highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
		show_stop_reason = true, -- show stop reason when stopped for exceptions
		only_first_definition = true, -- only show virtual text at first definition (if there are multiple)
		all_references = true, -- show virtual text on all all references of the variable (not only definitions)

		-- experimental features:
		virt_text_pos = "eol", -- position of virtual text, see `:h nvim_buf_set_extmark()`
		all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
		virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
	})
end

return M
