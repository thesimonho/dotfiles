-- Stop newline comment continuation
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt.formatoptions = vim.opt.formatoptions - { "r", "o", "t", "c" }
	end,
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
})

-- show nvimtree hydra on focus
-- local nvimtree_group = vim.api.nvim_create_augroup("NvimTreeHydra", { clear = true })
-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
-- 	pattern = "*",
-- 	callback = function(opts)
-- 		if vim.bo[opts.buf].filetype == "NvimTree" then
-- 			spawn_nvim_tree_hydra()
-- 		else
-- 			if nvim_tree_hydra then
-- 				nvim_tree_hydra:exit()
-- 			end
-- 		end
-- 	end,
-- 	group = nvimtree_group,
-- })
