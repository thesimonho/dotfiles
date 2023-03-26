local M = {
	"nvim-tree/nvim-tree.lua",
	cond = vim.g.vscode == nil,
	enabled = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "NvimTreeToggle", "NvimTreeOpen" },
}

function M.config()
	local HEIGHT_RATIO = 0.8
	local WIDTH_RATIO = 0.18

	require("nvim-tree").setup({
		auto_reload_on_write = true,
		disable_netrw = true,
		hijack_cursor = true,
		sync_root_with_cwd = true,
		respect_buf_cwd = true,
		reload_on_bufenter = false,
		select_prompts = true,
		view = {
			centralize_selection = false,
			cursorline = true,
			signcolumn = "no",
			width = function()
				return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
			end,
			hide_root_folder = false,
			side = "left",
			preserve_window_proportions = true,
			float = {
				enable = false,
				quit_on_focus_loss = true,
				open_win_config = function()
					local screen_w = vim.opt.columns:get()
					local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
					local window_w = screen_w * WIDTH_RATIO
					local window_h = screen_h * HEIGHT_RATIO
					local window_w_int = math.floor(window_w)
					local window_h_int = math.floor(window_h)
					local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
					return {
						border = "single",
						relative = "editor",
						row = center_y,
						col = 2,
						width = window_w_int,
						height = window_h_int,
					}
				end,
			},
		},
		renderer = {
			highlight_git = true,
			full_name = false,
			highlight_opened_files = "name",
			highlight_modified = "name",
			root_folder_label = ":~:s?$?",
			indent_markers = {
				enable = true,
				inline_arrows = true,
			},
			icons = {
				webdev_colors = true,
				git_placement = "before",
				modified_placement = "after",
				padding = " ",
				show = {
					file = true,
					folder = true,
					folder_arrow = true,
					git = true,
					modified = true,
				},
				glyphs = {
					git = {
						unstaged = "",
						staged = "",
						unmerged = "",
						renamed = "",
						untracked = "",
						deleted = "",
						ignored = "◌",
					},
				},
			},
			special_files = {},
			symlink_destination = false,
		},
		update_focused_file = {
			enable = true,
			update_root = false,
		},
		filters = {
			dotfiles = false,
			git_clean = false,
			no_buffer = false,
		},
		filesystem_watchers = {
			enable = true,
		},
		git = {
			enable = true,
			ignore = false,
			show_on_dirs = true,
			show_on_open_dirs = true,
		},
		modified = {
			enable = true,
			show_on_dirs = true,
			show_on_open_dirs = true,
		},
		actions = {
			change_dir = {
				enable = false,
				global = false,
				restrict_above_cwd = false,
			},
			open_file = {
				quit_on_open = true,
				resize_window = true,
				window_picker = {
					enable = false,
				},
			},
			remove_file = {
				close_window = true,
			},
		},
		live_filter = {
			prefix = "[Filter]: ",
			always_show_folders = false,
		},
		tab = {
			sync = {
				open = true,
				close = true,
			},
		},
		notify = {
			threshold = vim.log.levels.INFO,
		},
	})
end

return M
