local M = {
	"saecki/crates.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = "nvim-lua/plenary.nvim",
	event = { "BufRead Cargo.toml" },
}

function M.config()
	require("crates").setup({
		null_ls = {
			enabled = true,
		},
		popup = {
			autofocus = true,
			hide_on_select = true,
		},
	})
    require("crates").show()
end

return M
