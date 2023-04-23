local M = {
	"nvim-neo-tree/neo-tree.nvim",
	enabled = true,
	branch = "v2.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	event = "VeryLazy",
}

function M.config()
	local function open_no_focus(state)
		local node = state.tree:get_node()
		if require("neo-tree.utils").is_expandable(node) then
			state.commands["toggle_node"](state)
		else
			state.commands["open"](state)
			vim.cmd("Neotree reveal")
		end
	end

	require("neo-tree").setup({
		close_if_last_window = true,
		popup_border_style = "single",
		enable_git_status = true,
		enable_modified_markers = true,
		enable_diagnostics = false,
		sort_case_insensitive = true,
		default_component_configs = {
			indent = {
				with_markers = false,
				with_expanders = true,
			},
			modified = {
				symbol = " ",
				highlight = "NeoTreeModified",
			},
			icon = {
				folder_closed = "",
				folder_open = "",
				folder_empty = "",
				folder_empty_open = "",
			},
			git_status = {
				symbols = {
					-- Change type
					added = "",
					deleted = "",
					modified = "",
					renamed = "",
					-- Status type
					untracked = "",
					ignored = "",
					unstaged = "",
					staged = "",
					conflict = "",
				},
			},
		},
		window = {
			position = "left",
			width = 35,
			popup = {
				position = { col = "2", row = "3" },
				size = function(state)
					local root_name = vim.fn.fnamemodify(state.path, ":~")
					local root_len = string.len(root_name) + 4
					return {
						width = math.max(root_len, 50),
						height = vim.o.lines - 6,
					}
				end,
			},
			mappings = {
				["<space>"] = "none",
				["<cr>"] = open_no_focus,
				["<tab>"] = open_no_focus,
				["a"] = {
					"add",
					config = {
						show_path = "relative", -- "none", "relative", "absolute"
					},
				},
				["A"] = {
					"add_directory",
					config = {
						show_path = "relative", -- "none", "relative", "absolute"
					},
				},
				["c"] = {
					"copy",
					config = {
						show_path = "relative", -- "none", "relative", "absolute"
					},
				},
				["m"] = {
					"move",
					config = {
						show_path = "relative", -- "none", "relative", "absolute"
					},
				},
			},
		},
		source_selector = {
			winbar = false,
		},
		filesystem = {
			bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
			cwd_target = {
				sidebar = "tab", -- match this to however cd is set elsewhere (tab, window, global)
			},
			filtered_items = {
				visible = false, -- when true, they will just be displayed differently than normal items
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_hidden = true, -- only works on Windows for hidden files/directories
			},
			follow_current_file = true,
			hide_by_name = {
				".DS_Store",
				"thumbs.db",
			},
			use_libuv_file_watcher = true, -- This will use the OS level file watchers to detect changes
		},
		buffers = {
			follow_current_file = true,
			group_empty_dirs = false,
		},
		git_status = {
			window = {
				position = "float",
			},
		},
		event_handlers = {
			{
				event = "neo_tree_window_after_open",
				handler = function(args)
					if args.position == "left" or args.position == "right" then
						vim.cmd("wincmd =")
					end
				end,
			},
			{
				event = "neo_tree_window_after_close",
				handler = function(args)
					if args.position == "left" or args.position == "right" then
						vim.cmd("wincmd =")
					end
				end,
			},
		},
	})
end

return M
