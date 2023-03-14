local M = {
	"stevearc/aerial.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	cmd = { "AerialToggle", "AerialOpen", "AerialOpenAll" },
}

function M.config()
	require("aerial").setup({
		on_attach = function(bufnr)
			vim.keymap.set("n", "[a", "<cmd>AerialPrev<CR>", { desc = "Previous aerial", buffer = bufnr })
			vim.keymap.set("n", "]a", "<cmd>AerialNext<CR>", { desc = "Next aerial", buffer = bufnr })
		end,
		backends = { "lsp", "treesitter", "markdown", "man" },
		layout = {
			-- max_width = { 40, 0.2 },
			-- width = nil,
			-- min_width = 10,
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
