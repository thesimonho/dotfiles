return {
	name = "format",
	builder = function()
		return {
			cmd = { "terraform" },
			args = {  "fmt", "--recursive" },
			components = { { "on_complete_notify" }, "default" },
		}
	end,
	condition = {
		filetype = { "terraform" },
	},
}
