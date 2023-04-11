local M = {
	"nvim-lualine/lualine.nvim",
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

	local empty = require("lualine.component"):extend()
	function empty:draw(default_highlight)
		self.status = ""
		self.applied_separator = ""
		self:apply_highlights(default_highlight)
		self:apply_section_separators()
		return self.status
	end

	-- TODO: nvchad style separator icons: https://github.com/NvChad/ui/tree/v2.0/lua/nvchad_ui/statusline
	-- this is maybe a custom lualine theme?

	local function process_sections(sections)
		for name, section in pairs(sections) do
			local left = name:sub(9, 10) < "x"
			for pos = 1, name ~= "lualine_z" and #section or #section - 1 do
				table.insert(section, pos * 2, { empty, color = { bg = require("colours").status } })
			end
			for id, comp in ipairs(section) do
				if type(comp) ~= "table" then
					comp = { comp }
					section[id] = comp
				end
				comp.separator = left and { right = "" } or { left = "" }
			end
		end
		return sections
	end

	require("lualine").setup({
		options = {
			theme = custom,
			globalstatus = true,
			section_separators = { left = "", right = "" },
			component_separators = "",
			disabled_filetypes = {
				statusline = { "alpha" },
				winbar = { "neo-tree", "aerial", "OverseerList", "alpha" },
			},
		},
		sections = process_sections({
			lualine_a = { { "mode", padding = 2 } },
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
					symbols = { added = "+", modified = "⇆ ", removed = "-" },
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
					"overseer",
					on_click = function()
						vim.cmd("OverseerToggle")
					end,
				},
			},
			lualine_x = {},
			lualine_y = {
				"filetype",
				{
					function()
						local msg = "No active LSP"
						local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
						local clients = vim.lsp.get_active_clients()
						if next(clients) == nil then
							return msg
						end
						for _, client in ipairs(clients) do
							local filetypes = client.config.filetypes
							if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
								return client.name
							end
						end
						return msg
					end,
					icon = "  LSP:",
					on_click = function()
						vim.cmd("LspInfo")
					end,
				},
			},
			lualine_z = {
				{
					"location",
					fmt = function(str, _)
						local loc = vim.split(str, ":")
						return string.format("L:%d C:%d", loc[1], loc[2])
					end,
				},
				{ "progress", padding = 2 },
			},
		}),
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {},
			lualine_x = { { "filetype", color = { fg = "grey" }, colored = false } },
			lualine_y = {},
			lualine_z = {},
		},
		winbar = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{ "filetype", colored = true, icon_only = true },
				{
					"filename",
					color = { fg = require("colours").textLight },
					symbols = {
						modified = "", -- Text to show when the file is modified.
						readonly = "(RO)", -- Text to show when the file is non-modifiable or readonly.
					},
					padding = { left = 0, right = 4 },
				},
				{
					"aerial",
					depth = 3,
					on_click = function()
						vim.cmd("AerialToggle")
					end,
				},
			},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		inactive_winbar = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{ "filetype", colored = false, icon_only = true },
				{
					"filename",
					symbols = {
						modified = "", -- Text to show when the file is modified.
						readonly = "(RO)", -- Text to show when the file is non-modifiable or readonly.
					},
					padding = { left = 0, right = 4 },
				},
			},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		extensions = {
			"aerial",
			"man",
			"neo-tree",
			"nvim-dap-ui",
			"quickfix",
			"toggleterm",
			"overseer",
		},
	})
end

return M
