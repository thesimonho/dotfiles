local M = {
	"dstein64/vim-startuptime",
	enabled = true,
	cmd = "StartupTime",
}

function M.config()
    vim.g.startuptime_tries = 10
end

return M
