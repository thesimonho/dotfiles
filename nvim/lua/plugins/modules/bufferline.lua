local M = {
	"akinsho/bufferline.nvim",
	enabled = true,
	version = "v3.5.0",
	dependencies = { "nvim-tree/nvim-web-devicons", "tiagovla/scope.nvim" },
	event = "VimEnter",
}

function M.config()
	local palette = require("colours")

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
			offsets = {
				{
					filetype = "aerial",
					text = "Outline",
					text_align = "center",
					separator = false,
				},
				{
					filetype = "OverseerList",
					text = "Tasks",
					text_align = "center",
					separator = false,
				},
			},
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
						matcher = function(buf)
							return buf.filename:match("%.md") or buf.filename:match("%.txt")
						end,
					},
					{
						name = "Tests",
						highlight = { bold = false, italic = false, sp = "blue" },
						auto_close = false,
						priority = 2,
						matcher = function(buf)
							return buf.filename:match("%.test") or buf.filename:match("%.spec")
						end,
					},
					{
						name = "Config",
						highlight = { bold = false, italic = false, sp = "red" },
						auto_close = false,
						priority = 3,
						matcher = function(buf)
							return buf.filename:match("%.toml")
								or buf.filename:match("%.yaml")
								or buf.filename:match("%.cfg")
						end,
					},
				},
			},
		},
		highlights = {
			-- fill = {
			-- 	fg = palette.autumnRed,
			-- 	bg = palette.status,
			-- },
			-- background = {
			-- 	fg = palette.autumnRed,
			-- 	bg = palette.status,
			-- },
			-- tab = {
			-- 	fg = palette.autumnRed,
			-- 	bg = palette.autumnRed,
			-- },
			tab_selected = {
				fg = palette.bufModified,
				bg = palette.status,
				bold = true,
			},
			tab_close = {
				fg = palette.textLight,
				bg = palette.bufClose,
			},
			-- close_button = {
			-- 	fg = palette.autumnRed,
			-- 	bg = palette.autumnRed,
			-- },
			close_button_visible = {
				fg = palette.bufClose,
				bg = palette.bufVisible,
			},
			close_button_selected = {
				fg = palette.bufClose,
				bg = palette.bufSelected,
			},
			buffer_visible = {
				fg = palette.textDark,
				bg = palette.bufVisible,
			},
			buffer_selected = {
				fg = palette.textDark,
				bg = palette.bufSelected,
				bold = false,
				italic = false,
			},
			modified = {
				fg = palette.bufModified,
				-- bg = palette.autumnRed,
			},
			modified_visible = {
				fg = palette.bufModified,
				bg = palette.bufVisible,
			},
			modified_selected = {
				fg = palette.bufModified,
				bg = palette.bufSelected,
			},
			duplicate_selected = {
				fg = palette.comment,
				bg = palette.bufSelected,
				italic = false,
			},
			duplicate_visible = {
				fg = palette.comment,
				bg = palette.bufVisible,
				italic = false,
			},
			duplicate = {
				fg = palette.comment,
				-- bg = palette.autumnRed,
				italic = false,
			},
			separator_selected = {
				-- fg = palette.autumnRed,
				bg = palette.bufSelected,
			},
			separator_visible = {
				-- fg = palette.bufPick,
				bg = palette.bufVisible,
			},
			-- separator = {
			-- 	fg = palette.autumnRed,
			-- 	bg = palette.autumnRed,
			-- },
			indicator_selected = {
				fg = palette.bufSelected,
				bg = palette.bufSelected,
			},
			indicator_visible = {
				fg = palette.bufVisible,
				bg = palette.bufVisible,
			},
			pick_selected = {
				fg = palette.bufPick,
				bg = palette.bufSelected,
				bold = true,
				italic = false,
			},
			pick_visible = {
				fg = palette.bufPick,
				bg = palette.bufVisible,
				bold = true,
				italic = false,
			},
			pick = {
				fg = palette.bufPick,
				-- bg = palette.bufNormal,
				bold = true,
				italic = false,
			},
			offset_separator = {
				fg = palette.bufPick,
				bg = palette.bufVisible,
			},
		},
	})

	require("scope").setup()
end

return M
