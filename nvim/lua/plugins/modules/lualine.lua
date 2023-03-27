local M = {
	"nvim-lualine/lualine.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	local colours = require("colours")
	local custom = require("lualine.themes.base16")
	local utils = require("utils")
	custom.normal.a.bg = colours.normal
	custom.insert.a.bg = colours.insert
	custom.visual.a.bg = colours.visual
	custom.command.a.bg = colours.command
	custom.replace.a.bg = colours.replace

	require("lualine").setup({
		options = {
			theme = custom,
			globalstatus = true,
			-- section_separators = { left = "", right = "" },
			-- component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			component_separators = { left = "", right = "" },
		},
		sections = {
			lualine_a = { { "mode", padding = 1 } },
			lualine_b = {
				{
					"branch",
					color = utils.get_mode_colour,
					on_click = function()
						require("telescope.builtin").git_branches()
					end,
				},
				{
					"diff",
					on_click = function()
						require("telescope.builtin").git_status()
					end,
				},
				{
					"diagnostics",
					on_click = function()
						vim.cmd("TroubleToggle")
					end,
				},
			},
			lualine_c = {
				{
					"aerial",
					depth = 1,
					on_click = function()
						vim.cmd("AerialToggle")
					end,
				},
			},
			lualine_x = {
				{
					"overseer",
					on_click = function()
						vim.cmd("OverseerToggle")
					end,
				},
			},
			lualine_y = { "fileformat", "filetype" },
			lualine_z = {
				{
					"location",
					fmt = function(str, _)
						local loc = utils.split(str, ":")
						return string.format("L:%d C:%d", loc[1], loc[2])
					end,
				},
				"progress",
			},
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {},
			lualine_x = { { "filetype", color = { fg = "grey" }, colored = false } },
			lualine_y = {},
			lualine_z = {},
		},
		extensions = {
			"man",
			"aerial",
			"neo-tree",
			"nvim-dap-ui",
			"toggleterm",
			"overseer",
		},
	})
end

return M
