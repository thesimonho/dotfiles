local M = {
	"jpalardy/vim-slime",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = "klafyvel/vim-slime-cells",
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	vim.g.slime_target = "neovim"
	vim.g.slime_no_mappings = 1
	vim.g.slime_dont_ask_default = 1
	vim.g.slime_python_ipython = 1
	vim.g.slime_bracketed_paste = 1
	-- vim.g.slime_cell_delimiter = [[^```{\?\a\+}\?$]]
	vim.g.slime_cell_delimiter = "^```"
end

return M