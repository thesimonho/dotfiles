return {
	name = "plan",
	builder = function()
		return {
			cmd = { "terraform" },
			args = { "plan" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "terraform" },
	},
}
