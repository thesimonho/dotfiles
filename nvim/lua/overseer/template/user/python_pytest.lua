return {
	name = "pytest",
	builder = function()
		local file = vim.fn.expand("%:p")
		return {
			cmd = { "pytest" },
			-- args = { file },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "python" },
	},
}
