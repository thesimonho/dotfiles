-- Remember to run :KanagawaCompile after editing
-- https://github.com/rebelot/kanagawa.nvim

local M = {
	"rebelot/kanagawa.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	lazy = false, -- make sure we load this during startup
	priority = 1000, -- make sure to load this before all the other start plugins
}

function M.config()
	local wave = require("kanagawa.colors").setup({ theme = "wave" }) -- borrow colours from wave theme
	local wave_theme = wave.theme
	local palette = wave.palette

	require("kanagawa").setup({
		compile = true,
		undercurl = true,
		dimInactive = true, -- dim inactive window `:h hl-NormalNC`
		commentStyle = { italic = true }, -- comments
		functionStyle = { italic = false }, -- names of functions
		keywordStyle = { italic = false, bold = false }, -- language keywords (e.g. function, local, etc.)
		statementStyle = { italic = false, bold = false },
		typeStyle = { italic = false }, -- type hints/declarations
		terminalColors = true,
		colors = {
			palette = {},
			theme = {
				wave = {},
				lotus = {},
				dragon = {
					ui = { -- use wave theme colors
						fg = wave_theme.ui.fg,
						fg_dim = wave_theme.ui.fg_dim,
						fg_reverse = wave_theme.ui.fg_reverse,

						bg_dim = wave_theme.ui.bg_dim,
						bg_m3 = wave_theme.ui.bg_m3,
						bg_m2 = wave_theme.ui.bg_m2,
						bg_m1 = wave_theme.ui.bg_m1,
						bg = wave_theme.ui.bg,
						bg_p1 = wave_theme.ui.bg_p1,
						bg_p2 = wave_theme.ui.bg_p2,

						special = wave_theme.ui.special,
						nontext = wave_theme.ui.nontext,
						whitespace = wave_theme.ui.whitespace,

						bg_search = wave_theme.ui.bg_search,
						bg_visual = wave_theme.ui.bg_visual,

						pmenu = {
							fg = wave_theme.ui.pmenu.fg,
							bg = wave_theme.ui.pmenu.bg,
							bg_sel = wave_theme.ui.pmenu.bg_sel,
							bg_sbar = wave_theme.ui.pmenu.bg_sbar,
							bg_thumb = wave_theme.ui.pmenu.bg_thumb,
						},
						float = {
							fg = wave_theme.ui.float.fg,
							bg = wave_theme.ui.float.bg,
							fg_border = wave_theme.ui.float.fg_border,
							bg_border = wave_theme.ui.bg,
						},
					},
					syn = { comment = wave_theme.syn.comment },
				},
				all = { ui = { bg_gutter = "none", pmenu = { fg_sel = "none" } } },
			},
		},
		overrides = function(colors) -- add/modify highlights
			return {
				DiagnosticVirtualTextError = { fg = colors.palette.samuraiRed },
				DiagnosticVirtualTextWarn = { fg = colors.palette.roninYellow },
				DiagnosticVirtualTextInfo = { fg = colors.palette.waveAqua1 },
				DiagnosticVirtualTextHint = { fg = colors.palette.dragonBlue },

				BufferCurrent = { bg = colors.palette.sumiInk4 },
				BufferCurrentTarget = { fg = colors.palette.autumnRed, bg = colors.palette.sumiInk4 },
				BufferCurrentSign = { bg = colors.palette.sumiInk4 },
				BufferCurrentMod = { fg = colors.palette.roninYellow, bg = colors.palette.sumiInk4 },
				BufferInactive = { bg = colors.palette.sumiInk4 },
				BufferInactiveTarget = { fg = colors.palette.autumnRed, bg = colors.palette.sumiInk4 },
				BufferInactiveSign = { bg = colors.palette.sumiInk4 },
				BufferInactiveMod = { fg = colors.palette.roninYellow, bg = colors.palette.sumiInk4 },

				IndentBlanklineChar = { fg = colors.palette.sumiInk4 },
				HLInclineNormal = { bg = colors.palette.fujiWhite, fg = colors.palette.sumiInk0 },
				HLInclineNormalNC = { bg = colors.palette.sumiInk4, fg = colors.palette.fujiWhite },

				LeapLabelPrimary = { fg = colors.palette.sumiInk0, bg = colors.palette.autumnRed },
				LeapLabelSecondary = { fg = colors.palette.sumiInk0, bg = colors.palette.autumnYellow },

				NeoTreeIndentMarker = { link = "IndentBlanklineChar" },
				NvimTreeRootFolder = { fg = colors.palette.autumnYellow },
				NvimTreeOpenedFolderName = { fg = colors.palette.dragonBlue },

				JupyniumCodeCellSeparator = { bg = colors.palette.winterYellow },
				JupyniumMarkdownCellSeparator = { bg = colors.palette.winterRed },
				JupyniumMarkdownCellContent = { bg = colors.palette.sumiInk4 },
				JupyniumMagicCommand = { link = "Keyword" },

				ScrollbarCursor = { fg = colors.palette.oldWhite },
				WhichKey = { fg = colors.palette.peachRed },
				YankyYanked = { bg = colors.palette.winterYellow },
				YankyPut = { bg = colors.palette.winterRed },
			}
		end,
		background = { -- set theme based on background color
			dark = "dragon",
			light = "lotus",
		},
	})

	-- load the colorscheme after config
	vim.cmd([[colorscheme kanagawa]])
end

return M
