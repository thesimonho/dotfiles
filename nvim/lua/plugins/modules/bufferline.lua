local M = {
	"akinsho/bufferline.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	version = "v3.5.0",
	dependencies = "nvim-tree/nvim-web-devicons",
	event = { "VimEnter" },
}

function M.config()
	require("bufferline").setup({
		options = {
			mode = "buffers", -- set to "tabs" to only show tabpages instead
			numbers = function(opts)
				return string.format("%s", opts.raise(opts.ordinal))
			end,
			close_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
			left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
			middle_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
			right_mouse_command = "vertical sbuffer %d", -- can be a string | function, see "Mouse actions"
			indicator = {
				style = "underline",
			},
			buffer_close_icon = "",
			modified_icon = "●",
			close_icon = "",
			left_trunc_marker = "",
			right_trunc_marker = "",
			max_name_length = 18,
			max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
			truncate_names = true, -- whether or not tab names should be truncated
			tab_size = 18,
			diagnostics = false,
			color_icons = true, -- whether or not to add the filetype icon highlights
			show_buffer_icons = true, -- disable filetype icons for buffers
			show_buffer_close_icons = true,
			show_buffer_default_icon = true, -- whether or not an unrecognised filetype should show a default icon
			show_close_icon = true,
			show_tab_indicators = true,
			show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
			persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
			separator_style = "slant",
			enforce_regular_tabs = false,
			always_show_bufferline = true,
			sort_by = "directory",
			groups = {
				options = {
					toggle_hidden_on_enter = true, -- when you re-enter a hidden group this options re-opens that group so the buffer is visible
				},
				items = {
					{
						name = "Docs",
						highlight = { undercurl = true, sp = "green" },
						auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
						priority = 1,
						matcher = function(buf)
							return buf.filename:match("%.md") or buf.filename:match("%.txt")
						end,
					},
					{
						name = "Tests", -- Mandatory
						highlight = { underline = true, sp = "blue" }, -- Optional
						auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
						priority = 2, -- determines where it will appear relative to other groups (Optional)
						icon = "", -- Optional
						matcher = function(buf) -- Mandatory
							return buf.filename:match("%_test") or buf.filename:match("%_spec")
						end,
					},
				},
			},
		},
	})
end

return M
