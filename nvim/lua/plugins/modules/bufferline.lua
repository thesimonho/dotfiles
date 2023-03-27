local M = {
	"akinsho/bufferline.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	version = "v3.5.0",
	dependencies = { "nvim-tree/nvim-web-devicons", "tiagovla/scope.nvim" },
	event = "VimEnter",
}

function M.config()
	require("bufferline").setup({
		options = {
			mode = "buffers", -- set to "tabs" to only show tabpages instead
			numbers = "none",
			close_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
			left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
			middle_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
			right_mouse_command = "vertical sbuffer %d", -- can be a string | function, see "Mouse actions"
			indicator = {
				icon = "▎", -- this should be omitted if indicator style is not 'icon'
				style = "icon",
			},
			buffer_close_icon = "",
			modified_icon = "●",
			close_icon = "",
			left_trunc_marker = "",
			right_trunc_marker = "",
			max_name_length = 18,
			max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
			truncate_names = true, -- whether or not tab names should be truncated
			tab_size = 22,
			diagnostics = false,
			color_icons = true, -- whether or not to add the filetype icon highlights
			show_buffer_icons = true, -- disable filetype icons for buffers
			show_buffer_close_icons = true,
			show_buffer_default_icon = true, -- whether or not an unrecognised filetype should show a default icon
			show_close_icon = true,
			show_tab_indicators = true,
			show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
			persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
			separator_style = "thick",
			enforce_regular_tabs = false,
			always_show_bufferline = true,
			sort_by = "directory",
			groups = {
				options = {
					toggle_hidden_on_enter = true, -- when you re-enter a hidden group this options re-opens the group
				},
				items = {
					require("bufferline.groups").builtin.pinned:with({ icon = "" }),
					{
						name = "Docs",
						highlight = { bold = false, italic = false, sp = "green" },
						auto_close = false,
						priority = 1,
						icon = "",
						matcher = function(buf)
							return buf.filename:match("%.md") or buf.filename:match("%.txt")
						end,
					},
					{
						name = "Tests",
						highlight = { bold = false, italic = false, sp = "blue" },
						auto_close = false,
						priority = 2,
						icon = "",
						matcher = function(buf)
							return buf.filename:match("%_test") or buf.filename:match("%_spec")
						end,
					},
					{
						name = "Config",
						highlight = { bold = false, italic = false, sp = "red" },
						auto_close = false,
						priority = 3,
						icon = "⚙️",
						matcher = function(buf)
							return buf.filename:match("%.toml") or buf.filename:match("%.yaml")
						end,
					},
				},
			},
		},
	})
	require("scope").setup()
end

return M
