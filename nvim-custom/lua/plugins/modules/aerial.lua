local M = {
	"stevearc/aerial.nvim",
	enabled = true,
    cond = vim.g.vscode == nil,
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
			default_direction = "right",
			preserve_equality = true,
		},
		float = {
			--   cursor - Opens float on top of the cursor
			--   editor - Opens float centered in the editor
			--   win    - Opens float centered in the window
			relative = "win",
			border = "rounded",
			max_height = 0.9,
			height = nil,
			min_height = { 8, 0.1 },
		},
		lazy_load = true,
		close_automatic_events = { "unsupported" },
		close_on_select = true,
		highlight_on_hover = true,
		show_guides = true,
	})
end

return M
