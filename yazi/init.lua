---@diagnostic disable: undefined-global

th.git = th.git or {}
th.git.modified_sign = " "
th.git.deleted_sign = " "
th.git.added_sign = " "
th.git.untracked_sign = "󰞋 "
th.git.ignored_sign = "󰿠 "
th.git.updated_sign = " "
require("git"):setup()

require("full-border"):setup({
	type = ui.Border.ROUNDED,
})
