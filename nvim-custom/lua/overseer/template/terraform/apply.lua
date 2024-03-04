return {
	name = "apply",
	builder = function()
		return {
			cmd = { "terraform" },
			args = { "apply" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "terraform" },
	},
}
