local M = {
	"nvim-treesitter/nvim-treesitter",
	enabled = true,
	build = function()
		require("nvim-treesitter.install").update({ with_sync = true })
	end,
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("nvim-treesitter.install").compilers = { "gcc", "clang", "mingw" }

	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"bash",
			"c",
			"c_sharp",
			"comment",
			"cpp",
			"css",
			"cuda",
			"dockerfile",
			"gdscript",
			"gitignore",
			"go",
			"hlsl",
			"html",
			"htmldjango",
			"java",
			"javascript",
			"jsdoc",
			"json",
			"json5",
			"jsonc",
			"julia",
			"latex",
			"lua",
			"markdown",
			"markdown_inline",
			"matlab",
			"norg",
			"python",
			"query",
			"r",
			"regex",
			"rst",
			"rust",
			"sql",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"yaml",
		},
		auto_install = true, -- disable if no tree-sitter cli installed
		ignore_install = {}, -- list of parsers to ignore installing
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
		playground = {
			enable = true,
			disable = {},
			updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
			persist_queries = false, -- Whether the query persists across vim sessions
			keybindings = {
				toggle_query_editor = "o",
				toggle_hl_groups = "i",
				toggle_injected_languages = "t",
				toggle_anonymous_nodes = "a",
				toggle_language_display = "I",
				focus_language = "f",
				unfocus_language = "F",
				update = "R",
				goto_node = "<cr>",
				show_help = "?",
			},
		},
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<leader>v",
				node_incremental = "+",
				scope_incremental = false,
				node_decremental = "_",
			},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true,

				keymaps = {
					-- You can use the capture groups defined in textobjects.scm
					["af"] = { query = "@function.outer", desc = "around a function" },
					["if"] = { query = "@function.inner", desc = "inner part of a function" },
					["ac"] = { query = "@class.outer", desc = "around a class" },
					["ic"] = { query = "@class.inner", desc = "inner part of a class" },
					["ai"] = { query = "@conditional.outer", desc = "around an if statement" },
					["ii"] = { query = "@conditional.inner", desc = "inner part of an if statement" },
					["al"] = { query = "@loop.outer", desc = "around a loop" },
					["il"] = { query = "@loop.inner", desc = "inner part of a loop" },
					["ap"] = { query = "@parameter.outer", desc = "around parameter" },
					["ip"] = { query = "@parameter.inner", desc = "inside a parameter" },
				},
				selection_modes = {
					["@parameter.outer"] = "v", -- charwise
					["@parameter.inner"] = "v", -- charwise
					["@function.outer"] = "v", -- charwise
					["@conditional.outer"] = "V", -- linewise
					["@loop.outer"] = "V", -- linewise
					["@class.outer"] = "<c-v>", -- blockwise
				},
				include_surrounding_whitespace = false,
			},
			move = {
				enable = true,
				set_jumps = true, -- whether to set jumps in the jumplist
				goto_previous_start = {
					["[f"] = { query = "@function.outer", desc = "Previous function" },
					["[c"] = { query = "@class.outer", desc = "Previous class" },
					["[p"] = { query = "@parameter.inner", desc = "Previous parameter" },
				},
				goto_next_start = {
					["]f"] = { query = "@function.outer", desc = "Next function" },
					["]c"] = { query = "@class.outer", desc = "Next class" },
					["]p"] = { query = "@parameter.inner", desc = "Next parameter" },
				},
			},
		},
	})
end

return M
