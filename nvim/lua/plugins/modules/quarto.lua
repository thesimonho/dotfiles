local M = {
	"quarto-dev/quarto-nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = {
		"jmbuhr/otter.nvim",
		"hrsh7th/nvim-cmp",
		"neovim/nvim-lspconfig",
		"nvim-treesitter/nvim-treesitter",
	},
	cmd = { "QuartoPreview", "QuartoActivate", "QuartoHover" },
}

function M.config()
	require("quarto").setup({
		debug = false,
		closePreviewOnExit = true,
		lspFeatures = {
			enabled = true,
			languages = { "r", "python", "julia" },
			chunks = "curly", -- 'curly' or 'all'
			diagnostics = {
				enabled = true,
				triggers = { "BufWrite" },
			},
			completion = {
				enabled = true,
			},
		},
	})
end

return M
