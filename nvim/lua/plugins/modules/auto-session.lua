local M = {
	"rmagatti/auto-session",
	cond = vim.g.vscode == nil,
	enabled = false,
	event = "VeryLazy",
}

function M.config()
	require("auto-session").setup({
		log_level = "error",
		auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
		auto_session_enabled = true,
		auto_session_enable_last_session = false,
		auto_session_create_enabled = true,
		auto_save_enabled = true,
		auto_restore_enabled = true,
		auto_session_suppress_dirs = nil,
		auto_session_use_git_branch = false,
		bypass_session_save_file_types = { "NvimTree", "aerial", "OverseerList" },
		cwd_change_handling = {
			restore_upcoming_session = true, -- boolean: restore session for upcoming cwd on cwd change
			pre_cwd_changed_hook = nil, -- This is called after auto_session code runs for the `DirChangedPre` autocmd
			post_cwd_changed_hook = nil, -- This is called after auto_session code runs for the `DirChanged` autocmd
		},
	})
end

return M
