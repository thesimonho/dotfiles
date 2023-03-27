local M = {
	"luk400/vim-jukit",
	cond = vim.g.vscode == nil,
	enabled = false,
	lazy = false,
}

function M.config()
	vim.g._jukit_python_os_cmd = "python"
	vim.g.jukit_terminal = "nvimterm"
	vim.g.jukit_auto_output_hist = 1
	vim.g.jukit_mappings_ext_enabled = { "py", "ipynb" }
	vim.g.jukit_convert_open_default = 0

	vim.g.jukit_output_new_os_window = 1
	vim.g.jukit_outhist_new_os_window = 1
    vim.g.jukit_mpl_block = 0
	vim.g.jukit_inline_plotting = 1
end

return M
