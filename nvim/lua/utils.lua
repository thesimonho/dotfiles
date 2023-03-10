local M = {}

-- Functional wrapper for mapping custom keybindings
M.map = function(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- move or create split in direction
local opposite_keys = { h = "l", l = "h", j = "k", k = "j" }

local function split_exists_direction(winnr, direction)
	vim.cmd("wincmd " .. direction)
	if winnr == vim.api.nvim_get_current_win() then
		return false
	else
		vim.cmd("wincmd " .. opposite_keys[direction])
		return true
	end
end

M.move_create_split = function(direction)
	local winnr = vim.api.nvim_get_current_win()

	if split_exists_direction(winnr, direction) == false then
		if direction == "h" or direction == "l" then
			vim.cmd("wincmd v")
			vim.cmd("wincmd " .. direction)
		elseif direction == "j" or direction == "k" then
			vim.cmd("wincmd s")
			vim.cmd("wincmd " .. direction)
		end
	else
		vim.cmd("wincmd " .. direction)
	end
end

-- Get colour of the mode
local colours = require("colours")
M.get_mode_colour = function()
	local mode = vim.api.nvim_get_mode()["mode"]

	if mode == "n" then
		return { fg = colours.normal }
	elseif mode == "i" then
		return { fg = colours.insert }
	elseif mode == "v" then
		return { fg = colours.visual }
	elseif mode == "V" then
		return { fg = colours.visual }
	elseif mode == "s" then
		return { fg = colours.visual }
	elseif mode == "R" then
		return { fg = colours.replace }
	elseif mode == "c" then
		return { fg = colours.command }
	else
		return { fg = colours.text }
	end
end

-- open toggleterm with lazygit
local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({
	cmd = "lazygit",
	hidden = true,
	on_open = function(term)
		vim.cmd("startinsert!")
	end,
	close_on_exit = true,
	direction = "float",
	float_opts = {
		border = "single",
	},
})

M.toggle_lazygit = function()
	lazygit:toggle()
end

-- when grepping, cd to the project root directory first
M.live_grep_from_project_git_root = function()
	local function is_git_repo()
		vim.fn.system("git rev-parse --is-inside-work-tree")
		return vim.v.shell_error == 0
	end

	local function get_git_root()
		local dot_git_path = vim.fn.finddir(".git", ".;")
		return vim.fn.fnamemodify(dot_git_path, ":h")
	end

	local opts = {}

	if is_git_repo() then
		opts = {
			cwd = get_git_root(),
		}
	end

	require("telescope.builtin").live_grep(opts)
end

local ls = require("luasnip")
local sn = ls.snippet_node
local i = ls.insert_node
local f = ls.function_node

-- luasnip: insert visual selection into dynamic node
M.get_visual = function(parent)
	print("Creating snippet from visual selection...")
	if #parent.snippet.env.SELECT_RAW > 0 then
		return sn(nil, i(1, parent.snippet.env.SELECT_RAW))
	else
		return sn(nil, i(1, ""))
	end
end

-- luasnip: return the regex capture group for regex-based triggers
M.get_capture_group = function(group)
	return f(function(_, snip)
		return snip.captures[group]
	end)
end

-- preserve cursor location when running a command
-- eg `preserve_cursor("sil keepj normal! gg=G")`
-- https://stackoverflow.com/questions/70691265/restore-cursor-position-after-r
M.preserve_cursor = function(command)
	local arguments = string.format("keepjumps keeppatterns execute %q", command)
	-- local original_cursor = vim.fn.winsaveview()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_command(arguments)
	local lastline = vim.fn.line("$")
	-- vim.fn.winrestview(original_cursor)
	if line > lastline then
		line = lastline
	end
	vim.api.nvim_win_set_cursor({ 0 }, { line, col })
end

-- string split on separator
M.split = function(s, sep)
	local fields = {}
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c)
		fields[#fields + 1] = c
	end)

	return fields
end

-- check if string is in table
M.is_string_in_table = function(str, tbl)
	for _, value in pairs(tbl) do
		if value == str then
			return true
		end
	end
	return false
end

-- get all keys from a table
M.get_table_keys = function(tab)
	local keyset = {}
	for k, v in pairs(tab) do
		keyset[#keyset + 1] = k
	end
	return keyset
end

-- UI select menu
M.UI_select = function(item_map)
	local options = M.get_table_keys(item_map)
	return vim.ui.select(options, { prompt = "Select option" }, function(item, idx)
		for option, cmd in pairs(item_map) do
			if option == item then
				load(cmd)()
			end
		end
	end)
end

return M
