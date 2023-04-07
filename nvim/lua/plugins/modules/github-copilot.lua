local M = {
	"zbirenbaum/copilot.lua",
	cond = vim.g.vscode == nil,
	enabled = true,
	cmd = "Copilot",
	event = "InsertEnter",
}

function M.config()
	require("copilot").setup({
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 75,
			keymap = {
				accept = "<c-l>",
				accept_word = false,
				accept_line = false,
				dismiss = "<c-e>",
				next = "<c-j>",
				prev = "<c-k>",
			},
		},
	})
end

return M
