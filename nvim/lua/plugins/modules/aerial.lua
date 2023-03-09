local M = {
	"stevearc/aerial.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	cmd = { "AerialToggle", "AerialOpen", "AerialOpenAll" },
}

function M.config()
	require("aerial").setup({
		on_attach = function(bufnr)
			vim.keymap.set("n", "[a", "<cmd>AerialPrev<CR>", { buffer = bufnr })
			vim.keymap.set("n", "]a", "<cmd>AerialNext<CR>", { buffer = bufnr })
		end,
		layout = {
			default_direction = "right",
			preserve_equality = false,
		},
		close_automatic_events = { "unsupported" },
		highlight_on_hover = true,
		show_guides = true,
	})
end

return M
