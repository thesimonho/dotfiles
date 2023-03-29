-- Integrate Mason with nvim-dap
local M = {
	"jay-babu/mason-nvim-dap.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = {
		"williamboman/mason.nvim",
		"mfussenegger/nvim-dap",
		"mfussenegger/nvim-dap-python",
	},
	event = "VeryLazy",
}

function M.config()
	require("mason").setup()
	require("mason-nvim-dap").setup({
		ensure_installed = {
			"codelldb",
			"python",
		},
		automatic_setup = true,
	})

	-- setup mason-installed debugpy and python
	local path_debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/Scripts/python.exe"

	-- local path_python = vim.env.HOME .. "/miniconda3/python.exe"
	local path_python = vim.api.nvim_exec("!which python.exe", true)
	path_python = vim.split(path_python, "\n")[2] -- get result of the command
	path_python = path_python:gsub("^/(%a+)/", "%1:/")

	require("dap-python").setup(path_debugpy)
	require("dap-python").resolve_python = function()
		return path_python
	end

	-- set up rust and codelldb
	local dap = require("dap")
	local codelldb_root = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
	local codelldb_path = codelldb_root .. "adapter/codelldb.exe"
	local liblldb_path = codelldb_root .. "lldb/lib/liblldb.lib"

	dap.adapters.codelldb = {
		type = "server",
		port = "${port}",
		executable = {
			command = codelldb_path,
			args = { "--port", "${port}" },
			-- On windows you may have to uncomment this:
			-- detached = false,
		},
	}
	dap.configurations.rust = {
		{
			name = "Debug",
			type = "codelldb",
			request = "launch",
			program = function()
				vim.notify("Compiling a debug build for debugging. This might take some time...")
				vim.fn.jobstart("cargo build")

				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
			end,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			showDisassembly = "never",
		},
	}

	-- set debugger signs
	vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointCondition", { text = "ﳁ", texthl = "DapBreakpoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "", numhl = "" })
end
return M
