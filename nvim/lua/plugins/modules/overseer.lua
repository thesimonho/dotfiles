local M = {
	"stevearc/overseer.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	cmd = { "OverseerRun", "OverseerToggle" },
}

function M.config()
	require("overseer").setup({
		strategy = {
			"toggleterm",
			-- load your default shell before starting the task
			use_shell = true,
			-- overwrite the default toggleterm "direction" parameter
			direction = "horizontal",
			close_on_exit = false,
			-- open the toggleterm window when a task starts
			open_on_start = true,
			-- mirrors the toggleterm "hidden" parameter, and keeps the task from
			-- being rendered in the toggleable window
			hidden = false,
		},
		dap = true,
		auto_scroll = nil,
		close_on_exit = false,
		open_on_start = true,
		templates = { "builtin", "user.python_run", "user.scripts_run" },
	})
end

return M
