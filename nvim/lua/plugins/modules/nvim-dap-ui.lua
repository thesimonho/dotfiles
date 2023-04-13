local M = {
	"rcarriga/nvim-dap-ui",
	enabled = true,
	dependencies = { "mfussenegger/nvim-dap", "ChristianChiarulli/neovim-codicons" },
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	local dap, dapui = require("dap"), require("dapui")
	dapui.setup()

	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end
end

return M
