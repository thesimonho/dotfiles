local M = {
	"nvim-treesitter/nvim-treesitter",
    tag = "v0.8.5.2",
	enabled = true,
	build = function()
		require("nvim-treesitter.install").update({ with_sync = true })
	end,
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("nvim-treesitter.install").compilers = { "gcc", "clang", "mingw" }

	require("nvim-treesitter.configs").setup({
		ensure_installed = "all",
		auto_install = true, -- disable if no tree-sitter cli installed
		ignore_install = {}, -- list of parsers to ignore installing
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
		rainbow = {
			enable = true,
			extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
			colors = {
				"#cfcfcf",
				"#a89984",
				"#b16286",
				"#689d6a",
				"#457188",
				"#d79921",
				"#d65d0e",
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
