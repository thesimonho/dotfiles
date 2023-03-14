local M = {
	"romgrk/barbar.nvim",
	cond = vim.g.vscode == nil,
	enabled = false,
	dependencies = "nvim-tree/nvim-web-devicons",
	event = "VimEnter",
}

function M.config()
	require("bufferline").setup({
		animation = true,
		auto_hide = false,
		tabpages = true,
		closable = true,
		clickable = true,

		-- Hide inactive buffers and file extensions. Other options are `alternate`, `current`, and `visible`.
		hide = { extensions = false, inactive = false },

		highlight_alternate = false,
		highlight_inactive_file_icons = true,
		highlight_visible = false,

		icons = true,
		icon_pinned = "車",

		-- If set, the letters for each buffer in buffer-pick mode will be
		-- assigned based on their name. Otherwise or in case all letters are
		-- already assigned, the behavior is to assign letters in order of
		-- usability (see order below)
		semantic_letters = true,

		-- New buffer letters are assigned in this order. This order is
		-- optimal for the qwerty keyboard layout but might need adjustement
		-- for other layouts.
		letters = "asdfjklghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP",
	})
end

return M
