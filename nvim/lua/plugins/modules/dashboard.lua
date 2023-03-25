local M = {
	"glepnir/dashboard-nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VimEnter",
}

function M.config()
	require("dashboard").setup({
		theme = "hyper",
		disable_move = true,
		shortcut_type = "number",
		change_to_vcs_root = true,
		config = {
			week_header = { enable = true },
			packages = { enable = false },
			shortcut = {
				{
					icon = "💤",
					desc = " Lazy ",
					group = "@property",
					action = "Lazy home",
					key = "l",
				},
				{
					icon = "🧱",
					desc = " Mason ",
					group = "@property",
					action = "Mason",
					key = "m",
				},
				{
					icon = "🔍",
					desc = " Files ",
					group = "@parameter",
					action = "lua require'telescope.builtin'.find_files{}",
					key = "f",
				},
				{
					icon = "🔍",
					desc = " Projects ",
					group = "@parameter",
					action = "lua require'telescope'.extensions.project.project{}",
					key = "p",
				},
			},
			project = { enable = false }, -- disable recent projects section
			mru = { limit = 9 },
			footer = function()
				return { "", "-", "", "🐼 Never Half-Ass Two Things, Whole-Ass One Thing. 🐼" }
			end,
		},
	})
end

return M
