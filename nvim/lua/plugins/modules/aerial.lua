local M = {
	"stevearc/aerial.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
}

function M.config()
	require("aerial").setup({
		on_attach = function(bufnr)
			vim.keymap.set("n", "[a", "<cmd>AerialPrev<CR>", { buffer = bufnr })
			vim.keymap.set("n", "]a", "<cmd>AerialNext<CR>", { buffer = bufnr })
		end,
		backends = { "lsp", "treesitter", "markdown", "man" },
		layout = {
			max_width = 40,
			width = nil,
			min_width = 20,
			default_direction = "right",
			preserve_equality = false,
		},
		lazy_load = true,
		close_automatic_events = { "unsupported" },
		highlight_on_hover = true,
		show_guides = true,
	})
end

return M
