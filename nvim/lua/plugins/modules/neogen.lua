local M = {
	"danymat/neogen",
	enabled = false,
    cond = vim.g.vscode == nil,
	dependencies = "nvim-treesitter/nvim-treesitter",
	event = { "BufRead", "BufNewFile" },
}

function M.config()
	require("neogen").setup({
		snippet_engine = "luasnip",
		languages = {
			python = {
				template = {
					annotation_convention = "google_docstrings",
				},
			},
		},
	})
end

return M
