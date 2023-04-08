local utils = require("utils")
local map = utils.map
local Hydra = require("hydra")
local cmd = require("hydra.keymap-util").cmd
local pcmd = require("hydra.keymap-util").pcmd

-- ╔═════════════════════════════════════════════════╗
-- ║ General                                         ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>qq", "<cmd>qa<cr>") -- Quit all windows
map("n", "<C-S>", "<Cmd>silent! update | redraw<CR>", { desc = "Save" })
map({ "i", "x" }, "<C-S>", "<Esc><Cmd>silent! update | redraw<CR>", { desc = "Save and go to Normal mode" })
map("n", "<esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" }) -- Clear highlights on ESC
map("n", "cd", ":cd %:p:h<cr>:pwd<cr>", { desc = "Change working directory" }) -- cd to current file's directory
map("i", "<C-H>", "<C-W>", { desc = "Delete word backward" }) -- Delete word backwards; C-H = C-BS
map("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forward" }) -- Delete word forwards
map("n", "<Tab>", "<C-^>", { desc = "Alternate file" }) -- Switch to previous file

-- ╔═════════════════════════════════════════════════╗
-- ║ Movement                                        ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x" }, "gg", "mjgg", { desc = "Mark and go to top" }) -- Mark and go to top
map({ "n", "x" }, "G", "mjG", { desc = "Mark and go to bottom" }) -- Mark and go to bottom

map({ "n", "x" }, "w", "<Plug>(smartword-w)")
map({ "n", "x" }, "b", "<Plug>(smartword-b)")
map({ "n", "x" }, "j", "v:count ? 'j' : 'gj'", { expr = true, desc = "Down" }) -- Move down across wraps
map({ "n", "x" }, "k", "v:count ? 'k' : 'gk'", { expr = true, desc = "Up" }) -- Move up across wraps

map("i", "<M-h>", "<Left>", { noremap = false, desc = "Left" })
map("i", "<M-j>", "<Down>", { noremap = false, desc = "Down" })
map("i", "<M-k>", "<Up>", { noremap = false, desc = "Up" })
map("i", "<M-l>", "<Right>", { noremap = false, desc = "Right" })
map("t", "<M-h>", "<Left>", { desc = "Left" })
map("t", "<M-j>", "<Down>", { desc = "Down" })
map("t", "<M-k>", "<Up>", { desc = "Up" })
map("t", "<M-l>", "<Right>", { desc = "Right" })

map("n", "<M-h>", "<Plug>GoNSMLeft", { desc = "Move selection left" })
map("n", "<M-j>", "<Plug>GoNSMDown", { desc = "Move selection down" })
map("n", "<M-k>", "<Plug>GoNSMUp", { desc = "Move selection up" })
map("n", "<M-l>", "<Plug>GoNSMRight", { desc = "Move selection right" })
map("x", "<M-h>", "<Plug>GoVSMLeft", { desc = "Move selection left" })
map("x", "<M-j>", "<Plug>GoVSMDown", { desc = "Move selection down" })
map("x", "<M-k>", "<Plug>GoVSMUp", { desc = "Move selection up" })
map("x", "<M-l>", "<Plug>GoVSMRight", { desc = "Move selection right" })

map("n", "<M-Left>", "<Plug>GoNSDLeft", { desc = "Duplicate selection left" })
map("n", "<M-Down>", "<Plug>GoNSDDown", { desc = "Duplicate selection down" })
map("n", "<M-Up>", "<Plug>GoNSDUp", { desc = "Duplicate selection up" })
map("n", "<M-Right>", "<Plug>GoNSDRight", { desc = "Duplicate selection right" })
map("x", "<M-Left>", "<Plug>GoVSDLeft", { desc = "Duplicate selection left" })
map("x", "<M-Down>", "<Plug>GoVSDDown", { desc = "Duplicate selection down" })
map("x", "<M-Up>", "<Plug>GoVSDUp", { desc = "Duplicate selection up" })
map("x", "<M-Right>", "<Plug>GoVSDRight", { desc = "Duplicate selection right" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Leap                                            ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x", "o" }, "s", "<Plug>(leap-forward-to)", { desc = "Leap forward" })
map({ "n", "x", "o" }, "S", "<Plug>(leap-backward-to)", { desc = "Leap backward" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Refactoring                                     ║
-- ╚═════════════════════════════════════════════════╝
map(
	"v",
	"<leader>crf",
	[[ <Esc><cmd>lua require('refactoring').refactor('Extract Function')<cr>]],
	{ desc = "Extract to a function", expr = false }
)
map(
	"v",
	"<leader>crv",
	[[ <Esc><cmd>lua require('refactoring').refactor('Extract Variable')<cr>]],
	{ desc = "Extract to a variable", expr = false }
)
map(
	"n",
	"<leader>cri",
	[[ <cmd>lua require('refactoring').refactor('Inline Variable')<cr>]],
	{ desc = "Inline a variable", expr = false }
)
map(
	"n",
	"<leader>crpf",
	"<cmd>lua require('refactoring').debug.printf({below = false})<cr>",
	{ desc = "Add print statement (function)" }
)
map(
	"n",
	"<leader>crpv",
	"<cmd>lua require('refactoring').debug.print_var({ normal = true })<cr>",
	{ desc = "Add print statement (variable)" }
)
map("n", "<leader>crpc", "<cmd>lua require('refactoring').debug.cleanup({})<cr>", { desc = "Cleanup print statements" })

-- map("n", "<leader>R", "<CMD>SearchReplaceSingleBufferCWord<CR>", { desc = "Search and replace" })
-- map("v", "<leader>R", "<CMD>SearchReplaceSingleBufferVisualSelection<CR>", { desc = "Search and replace" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Help                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>?", "{}", { desc = "Help" })
map("n", "<leader>?h", "<cmd>lua require('telescope.builtin').help_tags()<cr>", { desc = "Help" })
map("n", "<leader>?k", "<cmd>lua require('telescope.builtin').keymaps()<cr>", { desc = "Keymaps" })
map("n", "<leader>?c", "<cmd>lua require('telescope.builtin').commands()<cr>", { desc = "Commands" })
map("n", "<leader>?a", "<cmd>lua require('telescope.builtin').autocommands()<cr>", { desc = "Autocommands" })
map("n", "<leader>?g", "<cmd>lua require('telescope.builtin').highlights()<cr>", { desc = "Highlight groups" })
map("n", "<leader>?v", "<cmd>lua require('telescope.builtin').vim_options()<cr>", { desc = "Vim options" })
map("n", "<leader>?n", "<cmd>NoiceHistory<cr>", { desc = "Notifications" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Tools                                           ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>z", "{}", { desc = "Tools" })
map("n", "<leader>zc", "<cmd>CccPick<cr>", { desc = "Colour picker" })
map("n", "<leader>zl", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>zm", "<cmd>Mason<cr>", { desc = "Mason" })
map("n", "<leader>zs", "<cmd>StartupTime<cr>", { desc = "StartupTime" })
map("n", "<leader>zS", "<cmd>lua require('luasnip.loaders').edit_snippet_files()<cr>", { desc = "Edit snippets" })
map("n", "<leader>zr", "<cmd>luafile %<CR>", { desc = "Source current file" })
map("n", "<leader>zt", "<cmd>TSPlaygroundToggle<CR>", { desc = "TS Playground" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Preview                                         ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>pm", "<cmd>MarkdownPreview<cr>", { desc = "Markdown" })
map("n", "<leader>pq", "<cmd>!start quarto preview %:p<cr>", { desc = "Quarto" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Window / Splits                                 ║
-- ╚═════════════════════════════════════════════════╝
local hint = [[
 ^^^^^^^^^^^^     Move       ^^    Size    ^^    _q_: close
 ^^^^^^^^^^^^-------------   ^^------------^^
 ^ ^ _k_ ^ ^  ^ ^ _K_ ^ ^   ^     _<up>_   ^
 _h_ ^ ^ _l_  _H_ ^ ^ _L_   _<left>_  _<right>_
 ^ ^ _j_ ^ ^  ^ ^ _J_ ^ ^   ^    _<down>_   ^  
 focus^^^^^^  window^^^^^^
]]

Hydra({
	name = "Windows",
	hint = hint,
	config = {
		invoke_on_body = true,
		hint = {
			position = "middle",
			border = "none",
		},
	},
	mode = "n",
	body = "<leader>w",
	heads = {
		{ "h", cmd("lua require('utils').move_create_split('h')"), { exit = true, desc = "Focus/split left" } },
		{ "j", cmd("lua require('utils').move_create_split('j')"), { exit = true, desc = "Focus/split down" } },
		{ "k", cmd("lua require('utils').move_create_split('k')"), { exit = true, desc = "Focus/split up" } },
		{ "l", cmd("lua require('utils').move_create_split('l')"), { exit = true, desc = "Focus/split right" } },

		{ "H", "<C-W>H", { exit = false, desc = "Move left" } },
		{ "J", "<C-W>J", { exit = false, desc = "Move down" } },
		{ "K", "<C-W>K", { exit = false, desc = "Move up" } },
		{ "L", "<C-W>L", { exit = false, desc = "Move right" } },

		{ "<up>", cmd("resize +15"), { exit = false, desc = "Resize up" } }, -- FIXME: fix the direction on these
		{ "<down>", cmd("resize -15"), { exit = false, desc = "Resize down" } },
		{ "<left>", cmd("vertical resize -15"), { exit = false, desc = "Resize left" } },
		{ "<right>", cmd("vertical resize +15"), { exit = false, desc = "Resize right" } },

		{ "q", pcmd("close", "E444"), { exit = true, desc = "close window" } },
		{ "<Esc>", nil, { exit = true, desc = false } },
	},
})

-- ╔═════════════════════════════════════════════════╗
-- ║ Buffers                                         ║
-- ╚═════════════════════════════════════════════════╝
local hint = [[
    _b_: Pick      _[_: Previous       _q_: Close
    _f_: Find      _]_: Next           _Q_: Close others
    _p_: Pin       _H_: Move left
    ^             _L_: Move right
    ]]
Hydra({
	name = "Buffers",
	hint = hint,
	config = {
		invoke_on_body = true,
		hint = {
			position = "top",
			offset = 2,
			border = "none",
		},
	},
	mode = "n",
	body = "<leader>b",
	heads = {
		{ "b", cmd("BufferLinePick"), { exit = true, desc = "Pick" } },
		{ "q", cmd("bp<bar>sp<bar>bn<bar>bd<CR>"), { exit = true, desc = "Close" } },
		{
			"Q",
			function()
				local cur_buf = vim.fn.bufnr()
				for _, e in ipairs(require("bufferline").get_elements().elements) do
					vim.schedule(function()
						if e.id ~= cur_buf then
							vim.cmd("bd " .. e.id)
						end
					end)
				end
			end,
			{ exit = true, desc = "Close others" },
		},
		{ "p", cmd("BufferLineTogglePin"), { exit = true, desc = "Pin" } },
		{ "f", cmd("lua require('telescope.builtin').buffers()"), { exit = true, desc = "Find" } },
		{ "[", cmd("BufferLineCyclePrev"), { exit = false, desc = "Prev" } },
		{ "]", cmd("BufferLineCycleNext"), { exit = false, desc = "Next" } },
		{ "H", cmd("BufferLineMovePrev"), { exit = false, desc = "Move Prev" } },
		{ "L", cmd("BufferLineMoveNext"), { exit = false, desc = "Move Next" } },
		{ "<Esc>", nil, { exit = true, desc = false } },
	},
})
map("n", "<c-b>", "<cmd>BufferLinePick<cr>")

-- ╔═════════════════════════════════════════════════╗
-- ║ Tabs                                            ║
-- ╚═════════════════════════════════════════════════╝
local hint = [[
    _t_: New       _[_: Previous
    _q_: Close     _]_: Next
    ]]
Hydra({
	name = "Tabs",
	hint = hint,
	config = {
		invoke_on_body = true,
		hint = {
			position = "top-right",
			offset = 2,
			border = "none",
		},
	},
	mode = "n",
	body = "<leader>t",
	heads = {
		{
			"t",
			function()
				vim.cmd("tabnew")
				require("telescope").extensions.project.project({})
			end,
			{ exit = true, desc = "New" },
		},
		{ "q", cmd("tabclose"), { exit = true, desc = "Close" } },
		{ "[", cmd("tabprev"), { exit = true, desc = "Prev" } },
		{ "]", cmd("tabnext"), { exit = true, desc = "Next" } },
		{ "<Esc>", nil, { exit = true, desc = false } },
	},
})

-- ╔═════════════════════════════════════════════════╗
-- ║ Folds                                           ║
-- ╚═════════════════════════════════════════════════╝
map("n", "zR", "<cmd>lua require('ufo').openAllFolds()<cr>", { desc = "Open all folds" })
map("n", "zM", "<cmd>lua require('ufo').closeAllFolds)<cr>", { desc = "Close all folds" })
map("n", "zr", "<cmd>lua require('ufo').openFoldsExceptKinds()<cr>", { desc = "Open folds except kinds" })
map("n", "zm", "<cmd>lua require('ufo').closeFoldsWithKinds()<cr>", { desc = "Close folds with kinds" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Find                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", { desc = "Files" })
map("n", "<leader>fg", "<cmd>lua require('utils').live_grep_from_project_root()<cr>", { desc = "Grep project" })
map("n", "<leader>fr", "<cmd>lua require('telescope.builtin').oldfiles()<cr>", { desc = "Recent" })
map("n", "<leader>fs", "<cmd>lua require('telescope.builtin').grep_string()<cr>", { desc = "String" })
map("n", "<leader>fp", "<cmd>lua require('telescope').extensions.project.project{}<cr>", { desc = "Project" })
map(
	"n",
	"<leader>fn",
	"<cmd>Neotree position=left reveal=true reveal_force_cwd=false toggle=true<cr>",
	{ desc = "Tree" }
)

-- ╔═════════════════════════════════════════════════╗
-- ║ Go to                                           ║
-- ╚═════════════════════════════════════════════════╝
local function show_hover()
	local filetype = vim.bo.filetype
	if vim.tbl_contains({ "vim", "help" }, filetype) then
		vim.cmd("h " .. vim.fn.expand("<cword>"))
	elseif vim.tbl_contains({ "man" }, filetype) then
		vim.cmd("Man " .. vim.fn.expand("<cword>"))
	elseif vim.fn.expand("%:t") == "Cargo.toml" and require("crates").popup_available() then
		require("crates").show_versions_popup()
	else
		vim.lsp.buf.hover()
	end
end
map("n", "<leader>gh", show_hover, { desc = "Hover" }) -- mapped outside otherwise types w/o LSP won't get the bind

function MapLSP(bufnr)
	map("n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { desc = "Declaration", buffer = bufnr })
	map("n", "<leader>gd", "<cmd>TroubleToggle lsp_definitions<cr>", { desc = "Definition", buffer = bufnr })
	map("n", "<leader>gt", "<cmd>TroubleToggle lsp_type_definitions<cr>", { desc = "Type Definition", buffer = bufnr })
	map("n", "<leader>gr", "<cmd>TroubleToggle lsp_references<cr>", { desc = "Find all references", buffer = bufnr })
	map("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", { desc = "Implementation", buffer = bufnr })
	map("n", "<leader>gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", { desc = "Signature", buffer = bufnr })
	map("n", "<leader>ge", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Show Error", buffer = bufnr })
	map("n", "<leader>gE", "<cmd>TroubleToggle<cr>", { desc = "Error List", buffer = bufnr })

	map("n", "[e", "<cmd>lua vim.diagnostic.goto_prev()<cr>", { desc = "Previous error", buffer = bufnr })
	map("n", "]e", "<cmd>lua vim.diagnostic.goto_next()<cr>", { desc = "Next error", buffer = bufnr })

	-- Binds that dont belong under "g" but should only be set when LSP is attached
	map("n", "<leader>crr", "<cmd>lua vim.lsp.buf.rename()<cr>", { desc = "LSP Rename" })
	map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "Code Action", buffer = bufnr })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Code                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<Leader>cd", "<cmd>lua require('neogen').generate()<CR>", { desc = "Generate docs" })
map("n", "<leader>cf", "<cmd>NullFormat<cr>", { desc = "Format" })
map("n", "<leader>co", "<cmd>AerialToggle<cr>", { desc = "Aerial Outline" })
map("n", "<leader>cs", "<cmd>TSJSplit<cr>", { desc = "Split line" })
map("n", "<leader>cj", "<cmd>TSJJoin<cr>", { desc = "Join line" })
map("n", "<leader>ct", "<cmd>TodoTelescope<cr>", { desc = "TODO" })
map("n", "<leader>cq", "<cmd>TroubleToggle quickfix<cr>", { desc = "Quickfix" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Snippets                                        ║
-- ╚═════════════════════════════════════════════════╝
map({ "i", "s" }, "<c-j>", function()
	if require("luasnip").expand_or_jumpable() then
		require("luasnip").expand_or_jump()
	end
end, { desc = "Next snippet placeholder" })

map({ "i", "s" }, "<c-k>", function()
	if require("luasnip").jumpable(-1) then
		require("luasnip").jump(-1)
	end
end, { desc = "Previous snippet placeholder" })

map("i", "<c-u>", "<cmd>lua require('luasnip.extras.select_choice')()<cr>", { desc = "Select choice" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Yanky                                           ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x" }, "<leader>y", "<cmd>Telescope yank_history<cr>", { desc = "Yanks" })
map({ "n", "x" }, "y", "<Plug>(YankyYank)")
map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
map("n", "[y", "<Plug>(YankyCycleBackward)", { desc = "Previous yank" })
map("n", "]y", "<Plug>(YankyCycleForward)", { desc = "Next yank" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Terminal                                        ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>`", function()
	utils.UI_select({
		["(→) Vertical"] = "vim.cmd('ToggleTerm direction=vertical')",
		["(↓) Horizontal"] = "vim.cmd('ToggleTerm direction=horizontal')",
		["(⤢) Float"] = "vim.cmd('ToggleTerm direction=float')",
	})
end, { desc = "Terminal" })
map("t", "<esc>", "<C-\\><C-n>") -- Escape to normal mode in terminal
map("t", "kj", "<C-\\><C-n>")

-- ╔═════════════════════════════════════════════════╗
-- ║ DAP / Debug                                     ║
-- ╚═════════════════════════════════════════════════╝
local hint = [[
 _<f5>_: Continue      _b_: Breakpoint      _h_: Hover         _f_: Frames
 _<f6>_: Step over     _r_: REPL            _p_: Preview       _s_: Scopes
 _<f7>_: Step into     _l_: Run last
 _<f8>_: Step out
]]
Hydra({
	name = "Debug",
	hint = hint,
	config = {
		color = "red",
		invoke_on_body = true,
		hint = {
			position = "bottom",
			border = "none",
		},
	},
	mode = { "n", "x" },
	body = "<leader>d",
	heads = {
		{ "<f5>", cmd("lua require('dap').continue()"), { exit = true, desc = "Continue" } },
		{ "<f6>", cmd("lua require('dap').step_over()"), { exit = false, desc = "Step over" } },
		{ "<f7>", cmd("lua require('dap').step_into()"), { exit = false, desc = "Step into" } },
		{ "<f8>", cmd("lua require('dap').step_out()"), { exit = false, desc = "Step out" } },
		{ "b", cmd("lua require('dap').toggle_breakpoint()"), { exit = false, desc = "Toggle breakpoint" } },
		{ "r", cmd("lua require('dap').repl.open()"), { exit = true, desc = "REPL" } },
		{ "l", cmd("lua require('dap').run_last()"), { exit = true, desc = "Run last" } },
		{ "h", cmd("lua require('dap.ui.widgets').hover()"), { exit = true, desc = "Hover" } },
		{ "p", cmd("lua require('dap.ui.widgets').preview()"), { exit = true, desc = "Preview" } },
		{
			"f",
			function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.frames)
			end,
			{ exit = true, desc = "Frames" },
		},
		{
			"s",
			function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.scopes)
			end,
			{ exit = true, desc = "Scopes" },
		},
		{ "<Esc>", nil, { exit = true, nowait = true, desc = false } },
	},
})

-- ╔═════════════════════════════════════════════════╗
-- ║ Git                                             ║
-- ╚═════════════════════════════════════════════════╝
local gitsigns = require("gitsigns")
local hint = [[
 _]_: next hunk    _s_: stage hunk        _d_: show deleted   _b_: blame line
 _[_: prev hunk    _S_: stage buffer      _p_: preview hunk   _B_: blame show full 
 _D_: diff view    _u_: undo last stage      ^ ^
 ^
 ^ ^              _<Enter>_: Lazygit
]]
Hydra({
	name = "Git",
	hint = hint,
	config = {
		color = "pink",
		invoke_on_body = true,
		hint = {
			position = "bottom",
			border = "none",
		},
		on_enter = function()
			vim.cmd("mkview")
			vim.cmd("silent! %foldopen!")
			vim.bo.modifiable = false
			gitsigns.toggle_linehl(true)
			gitsigns.toggle_deleted(true)
		end,
		on_exit = function()
			local cursor_pos = vim.api.nvim_win_get_cursor(0)
			vim.cmd("loadview")
			vim.api.nvim_win_set_cursor(0, cursor_pos)
			vim.cmd("normal zv")
			gitsigns.toggle_linehl(false)
			gitsigns.toggle_deleted(false)
		end,
	},
	mode = { "n", "x" },
	body = "<leader>G",
	heads = {
		{
			"]",
			function()
				if vim.wo.diff then
					return "]c"
				end
				vim.schedule(function()
					gitsigns.next_hunk()
				end)
				return "<Ignore>"
			end,
			{ expr = true, desc = "next hunk" },
		},
		{
			"[",
			function()
				if vim.wo.diff then
					return "[c"
				end
				vim.schedule(function()
					gitsigns.prev_hunk()
				end)
				return "<Ignore>"
			end,
			{ expr = true, desc = "prev hunk" },
		},
		{ "D", gitsigns.diffthis, { exit = false, silent = true, desc = "diff view" } },
		{ "s", cmd("Gitsigns stage_hunk"), { silent = true, desc = "stage hunk" } },
		{ "u", gitsigns.undo_stage_hunk, { desc = "undo last stage" } },
		{ "S", gitsigns.stage_buffer, { desc = "stage buffer" } },
		{ "p", gitsigns.preview_hunk, { desc = "preview hunk" } },
		{ "d", gitsigns.toggle_deleted, { nowait = true, desc = "toggle deleted" } },
		{ "b", gitsigns.blame_line, { desc = "blame" } },
		{
			"B",
			function()
				gitsigns.blame_line({ full = true })
			end,
			{ desc = "blame show full" },
		},
		{ "<Enter>", cmd("lua require('utils').toggle_lazygit()"), { exit = true, desc = "Lazygit" } },
		{ "<Esc>", nil, { exit = true, nowait = true, desc = false } },
	},
})

-- ╔═════════════════════════════════════════════════╗
-- ║ Overseer                                        ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<f5>", "<cmd>OverseerRun<cr>", { desc = "Overseer Run" })
map("n", "<c-f5>", "<cmd>OverseerToggle<cr>", { desc = "Overseer List" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Todo                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

map("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })

-- ╔═════════════════════════════════════════════════╗
-- ║ REPL                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>ro", function()
	utils.UI_select({
		["IPython"] = "require('utils').StartREPL('ipython')",
	})
end, { desc = "Open REPL" })

map("n", "<leader>rl", function()
	vim.cmd("SlimeSendCurrentLine")
	vim.api.nvim_command('SlimeSend0 "\n"')
end, { desc = "Send line" })

map("n", "<leader>rc", function()
	vim.cmd([[execute "normal \<Plug>SlimeCellsSendAndGoToNext"]])
	vim.api.nvim_command('SlimeSend0 "\n"')
end, { desc = "Send cell" })

map("v", "<leader>rv", function()
	vim.cmd("SlimeSend")
	vim.api.nvim_command('SlimeSend0 "\n"')
end, { desc = "Send visual selection" })

map("n", "[r", "<Plug>SlimeCellsPrev", { desc = "Previous REPL cell" })
map("n", "]r", "<Plug>SlimeCellsNext", { desc = "Next REPL cell" })
map("n", "<leader>rb", "o```{python}<cr>```<esc>O", { desc = "Insert code block" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Jupynium                                        ║
-- ╚═════════════════════════════════════════════════╝
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	pattern = { "*.ju.*" },
	callback = function(event)
		MapJupynium(event.buf)
	end,
})

function MapJupynium(bufnr)
	local tag_code = "# %%"
	local tag_md = "# %% [md]"

	local function go_to_end_of_cell()
		-- TODO: could simplify this by using the inside cell textobject
		local line_num_pre = vim.fn.line(".")
		require("jupynium.textobj").goto_next_cell_separator()
		local line_num_post = vim.fn.line(".")

		if line_num_pre == line_num_post then -- final cell
			vim.cmd(":$")
		else
			vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") - 1, 0 })
		end
	end

	local function insert_above(tag)
		vim.api.nvim_command("lua require('jupynium.textobj').goto_current_cell_separator()")
		vim.cmd("call append(line('.')-1, '')")
		vim.cmd("call append(line('.')-1, '')")
		vim.cmd("call append(line('.')-1, '')")
		vim.api.nvim_buf_set_lines(0, vim.fn.line(".") - 4, vim.fn.line(".") - 3, false, { tag })
		vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") - 2, 0 })
	end

	local function insert_below(tag)
		go_to_end_of_cell()

		vim.cmd("call append(line('.'), '')")
		vim.cmd("call append(line('.'), '')")
		vim.cmd("call append(line('.'), '')")
		vim.api.nvim_buf_set_lines(0, vim.fn.line("."), vim.fn.line(".") + 1, false, { tag })
		vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") + 2, 0 })
	end

	local function insert_md_quotes()
		vim.cmd("call append(line('.'), '')")
		vim.cmd("call append(line('.'), '')")
		vim.api.nvim_buf_set_lines(0, vim.fn.line(".") - 1, vim.fn.line("."), false, { '"""' })
		vim.api.nvim_buf_set_lines(0, vim.fn.line(".") + 1, vim.fn.line(".") + 2, false, { '"""' })
		vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") + 1, 0 })
	end

	local hint = [[
 _S_: Start server           _kh_: Kernel hover          _ac_: Code above         _[_: Prev cell
 _s_: Sync server            _kr_: Kernel restart        _am_: Markdown above     _]_: Next cell 
 _e_: Execute cell           _ks_: Kernel select         _bc_: Code below         _ij_: Inside cell 
 _E_: Execute all cells      _ki_: Kernel interrupt      _bm_: Markdown below     _aj_: Around cell 
]]
	Hydra({
		name = "Jupyter",
		hint = hint,
		config = {
			color = "red",
			invoke_on_body = true,
			hint = {
				position = "bottom-right",
				border = "none",
			},
		},
		mode = { "n", "x" },
		body = "<leader>j",
		heads = {
			{
				"S",
				cmd("JupyniumStartAndAttachToServer"),
				{ exit = true, buffer = bufnr, desc = "Start Jupynium server" },
			},
			{
				"s",
				function()
					filename_wo_ext = vim.fn.expand("%:r:r")
					vim.cmd([[JupyniumStartSync ]] .. filename_wo_ext)
				end,
				{ exit = true, buffer = bufnr, desc = "Sync server" },
			},
			{ "kh", cmd("JupyniumKernelHover"), { exit = true, buffer = bufnr, desc = "Hover" } },
			{ "kr", cmd("JupyniumKernelRestart"), { exit = true, buffer = bufnr, desc = "Restart kernel" } },
			{ "ks", cmd("JupyniumKernelSelect"), { exit = true, buffer = bufnr, desc = "Select kernel" } },
			{ "ki", cmd("JupyniumKernelInterrupt"), { exit = true, buffer = bufnr, desc = "Interrupt kernel" } },
			{
				"ac",
				function()
					insert_above(tag_code)
				end,
				{ exit = true, buffer = bufnr, desc = "Insert code above" },
			},
			{
				"am",
				function()
					insert_above(tag_md)
					insert_md_quotes()
				end,
				{ exit = true, buffer = bufnr, desc = "Insert markdown above" },
			},
			{
				"bc",
				function()
					insert_below(tag_code)
				end,
				{ exit = true, buffer = bufnr, desc = "Insert code below" },
			},
			{
				"bm",
				function()
					insert_below(tag_md)
					insert_md_quotes()
				end,
				{ exit = true, buffer = bufnr, desc = "Insert markdown below" },
			},
			{
				"j",
				cmd("lua require'jupynium.textobj'.goto_current_cell_separator()"),
				{ buffer = bufnr, desc = "Go to current cell" },
			},
			{ "e", cmd("JupyniumExecuteSelectedCells"), { exit = true, buffer = bufnr, desc = "Execute cell" } },
			-- TODO: jump back to prev cursor location
			{
				"E",
				"ggVG<cmd>JupyniumExecuteSelectedCells<cr><esc>",
				{ exit = true, buffer = bufnr, desc = "Execute all cells" },
			},
			{ "oc", cmd("JupyniumClearSelectedCellsOutputs"), { exit = false, buffer = bufnr, desc = "Clear output" } },
			{
				"ot",
				cmd("JupyniumToggleSelectedCellsOutputsScroll"),
				{ exit = true, buffer = bufnr, desc = "Toggle output" },
			},
			{
				"[",
				cmd("lua require'jupynium.textobj'.goto_previous_cell_separator()"),
				{ exit = false, buffer = bufnr, desc = "Previous cell" },
			},
			{
				"]",
				cmd("lua require'jupynium.textobj'.goto_next_cell_separator()"),
				{ exit = false, buffer = bufnr, desc = "Next cell" },
			},
			{
				"aj",
				cmd("lua require'jupynium.textobj'.select_cell(true, false)"),
				{ exit = true, buffer = bufnr, desc = "Around cell" },
			},
			{
				"ij",
				cmd("lua require'jupynium.textobj'.select_cell(false, false)"),
				{ exit = true, buffer = bufnr, desc = "Inside cell" },
			},
			{ "<Esc>", nil, { exit = true, buffer = bufnr, nowait = true, desc = false } },
		},
	})
end

