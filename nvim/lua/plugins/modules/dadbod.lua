local M = {
	"kristijanhusak/vim-dadbod-ui",
	enabled = true,
	dependencies = { "tpope/vim-dadbod", "kristijanhusak/vim-dadbod-completion" },
	cmd = { "DB", "DBUI", "DBUIAddConnection" },
}

vim.g.db_ui_show_help = 0
vim.g.db_ui_winwidth = 30

return M
