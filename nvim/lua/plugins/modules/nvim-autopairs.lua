local M = {
	"windwp/nvim-autopairs",
	enabled = true,
	event = "InsertEnter",
}

function M.config()
	require("nvim-autopairs").setup({
		check_ts = true,
		enable_check_bracket_line = true,
		iignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
		disable_filetype = { "TelescopePrompt" },
	})
end

return M
