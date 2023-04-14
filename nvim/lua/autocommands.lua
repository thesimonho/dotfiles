-- Stop newline comment continuation
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt.formatoptions = vim.opt.formatoptions - { "r", "o", "t", "c" }
	end,
	desc = "Disable comment continuation",
})

-- open help in right split
local help_group = vim.api.nvim_create_augroup("help_window_right", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = help_group,
	pattern = { "*.txt" },
	callback = function()
		if vim.o.filetype == "help" then
			vim.cmd.wincmd("L")
		end
	end,
	desc = "Open help pages in a vertical split",
})

-- insert mode when switching to terminal
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*",
	callback = function()
		if vim.api.nvim_buf_get_option(0, "buftype") == "terminal" then
			vim.api.nvim_command("startinsert")
		else
			vim.api.nvim_command("stopinsert")
		end
	end,
})

-- auto root
local root_group = vim.api.nvim_create_augroup("AutoRoot", {})
vim.api.nvim_create_autocmd("BufEnter", {
	group = root_group,
	callback = function()
		local patterns = { ".git", "package.json", "setup.py" }
		local root = require("utils").find_root(0, patterns)
		if root == nil then
			return
		end
		-- vim.fn.chdir(root)
		vim.cmd("tcd " .. root)
	end,
	desc = "Find root and change current directory",
})

-- alpha dashboard
local alpha_group = vim.api.nvim_create_augroup("alpha", { clear = true })
vim.api.nvim_create_autocmd("User", {
	group = alpha_group,
	pattern = "AlphaReady",
	command = "set laststatus=0 | set showtabline=0",
})
vim.api.nvim_create_autocmd("User", {
	group = alpha_group,
	pattern = "AlphaClosed",
	command = "set laststatus=3 | set showtabline=2",
})

-- minimap
local minimap_group = vim.api.nvim_create_augroup("minimap", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	group = minimap_group,
	command = "lua MiniMap.open()",
})
