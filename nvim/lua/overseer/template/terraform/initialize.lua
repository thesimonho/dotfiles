return {
	name = "init",
	builder = function()
		return {
			cmd = { "terraform" },
			args = {  "init" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "terraform" },
	},
}
