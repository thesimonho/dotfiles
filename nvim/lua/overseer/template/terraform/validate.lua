return {
	name = "validate",
	builder = function()
		return {
			cmd = { "terraform" },
			args = { "validate" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "terraform" },
	},
}
