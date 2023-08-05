return {
	name = "pytest",
	builder = function()
		return {
			cmd = { "pytest" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "python" },
	},
}
