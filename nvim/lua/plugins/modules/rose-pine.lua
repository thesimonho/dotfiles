local M = {
	"rose-pine/neovim",
	name = "rose-pine",
	cond = vim.g.vscode == nil,
	enabled = true,
	lazy = false, -- make sure we load this during startup
	priority = 1000, -- make sure to load this before all the other start plugins
}

function M.config()
	require("rose-pine").setup({
		dark_variant = "moon",
		bold_vert_split = false,
		disable_italics = true,
		highlight_groups = {
			NormalFloat = { bg = "overlay" },
			Pmenu = { bg = "surface" },
			IndentBlanklineChar = { fg = "highlight_low" },
			SignColumn = { guibg = NONE },

			BufferCurrent = { bg = "overlay", fg = "text" },
			BufferCurrentTarget = { bg = "overlay", fg = "love" },
			BufferCurrentSign = { bg = "overlay" },
			BufferCurrentMod = { bg = "overlay" },
			BufferInactive = { bg = "overlay", fg = "text" },
			BufferInactiveTarget = { bg = "overlay", fg = "love" },
			BufferInactiveSign = { bg = "overlay" },
			BufferInactiveMod = { bg = "overlay" },

			Headline1 = { bg = "pine" },
			Headline2 = { bg = "#345663" },
			CodeBlock = { bg = "overlay" },
			Dash = { bg = "love" },
			Quote = { bg = "love" },

			LeapLabelPrimary = { fg = "base", bg = "iris" },
			LeapLabelSecondary = { fg = "base", bg = "love" },
			NeoTreeRootName = { fg = "pine" },
			NeoTreeIndentMarker = { fg = "overlay" },
			TreesitterContext = { bg = "#345663" }, -- pine from rose pine dawn
			WhichKey = { fg = "love" },
			WhichKeyGroup = { fg = "subtle" },
			WhichKeyFloat = { bg = "overlay" },
			YankyYanked = { bg = "pine" },
			YankyPut = { bg = "#b4637a" }, -- love from rose pine dawn
		},
	})

	-- load the colorscheme after config
	vim.cmd([[colorscheme rose-pine]])
end

return M
