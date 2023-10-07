local M = {
	"NvChad/nvim-colorizer.lua",
	enabled = true,
	event = "BufRead",
}

function M.config()
	require 'colorizer'.setup()
end

return M
