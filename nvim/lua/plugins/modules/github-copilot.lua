local M = {
	"zbirenbaum/copilot.lua",
	cond = vim.g.vscode == nil,
	enabled = true,
	cmd = "Copilot",
	event = "InsertEnter",
}

function M.config()
	require("copilot").setup({
		panel = {
			enabled = true,
			auto_refresh = false,
			keymap = {
				jump_prev = "[[",
				jump_next = "]]",
				accept = "<CR>",
				refresh = "gr",
				open = "<M-CR>",
			},
			layout = {
				position = "bottom", -- | top | left | right
				ratio = 0.4,
			},
		},
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 75,
			keymap = {
				accept = "<c-l>",
				accept_word = false,
				accept_line = false,
				dismiss = "<C-e>",
				next = "<M-]>",
				prev = "<M-[>",
			},
		},
	})
end

return M
