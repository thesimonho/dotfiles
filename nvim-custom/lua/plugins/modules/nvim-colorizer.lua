local M = {
	"NvChad/nvim-colorizer.lua",
	enabled = true,
    cond = vim.g.vscode == nil,
	event = "BufRead",
}

function M.config()
	require 'colorizer'.setup()
end

return M
