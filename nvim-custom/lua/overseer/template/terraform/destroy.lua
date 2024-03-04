return {
	name = "destroy",
	builder = function()
		return {
			cmd = { "terraform" },
            args = { "destroy" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "terraform" },
	},
}
