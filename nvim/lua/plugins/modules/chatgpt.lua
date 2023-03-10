local M = {
	"jackMort/ChatGPT.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	cmd = { "ChatGPT", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
}

function M.config()
	require("chatgpt").setup({
		question_sign = "", -- you can use emoji if you want e.g. 🙂
		answer_sign = "ﮧ", -- 🤖
		max_line_length = 120,
		yank_register = "+",
		chat_layout = {
			relative = "editor",
			position = "50%",
			size = {
				height = "80%",
				width = "80%",
			},
		},
		settings_window = {
			border = {
				style = "rounded",
				text = {
					top = " Settings ",
				},
			},
		},
		chat_window = {
			filetype = "chatgpt",
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " ChatGPT ",
				},
			},
		},
		chat_input = {
			prompt = "  ",
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top_align = "center",
					top = " Prompt ",
				},
			},
		},
		openai_params = {
			model = "gpt-3.5-turbo",
			frequency_penalty = 0,
			presence_penalty = 0,
			max_tokens = 300,
			temperature = 0,
			top_p = 1,
			n = 1,
		},
		openai_edit_params = {
			model = "code-davinci-edit-001",
			temperature = 0,
			top_p = 1,
			n = 1,
		},
		keymaps = {
			close = { "<C-c>", "<Esc>" },
			yank_last = "<C-y>",
			scroll_up = "<C-u>",
			scroll_down = "<C-d>",
			toggle_settings = "<C-o>",
			new_session = "<C-n>",
			cycle_windows = "<Tab>",
			-- in the Sessions pane
			select_session = "<Space>",
			rename_session = "r",
			delete_session = "d",
		},
	})
end

return M
