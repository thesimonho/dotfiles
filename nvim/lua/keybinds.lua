local utils = require("utils")
local map = utils.map
local vscode = vim.g.vscode

-- ╔═════════════════════════════════════════════════╗
-- ║ General                                         ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>qq", "<cmd>qa<cr>") -- Quit all windows
map("n", "<C-S>", "<Cmd>silent! update | redraw<CR>", { desc = "Save" })
map({ "i", "x" }, "<C-S>", "<Esc><Cmd>silent! update | redraw<CR>", { desc = "Save and go to Normal mode" })
map("n", "<esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" }) -- Clear highlights on ESC
map("n", "cd", ":cd %:p:h<cr>:pwd<cr>", { desc = "Change working directory" }) -- Change directory to current file's directory
map("i", "<C-H>", "<C-W>", { desc = "Delete word backward" }) -- Delete word backwards; C-H = C-BS
map("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forward" }) -- Delete word forwards

-- ╔═════════════════════════════════════════════════╗
-- ║ Movement                                        ║
-- ╚═════════════════════════════════════════════════╝
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
-- ║ Undo (rest are in telescope module)             ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "<leader>u", "<cmd>Telescope undo<cr>", { desc = "Undo tree" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Help                                            ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "<leader>?k", '<cmd>call VSCodeNotify("workbench.action.keybindingsReference")<cr>')
else
	map("n", "<leader>?", "{}", { desc = "Help" })
	map("n", "<leader>?h", "<cmd>lua require('telescope.builtin').help_tags()<cr>", { desc = "Help" })
	map("n", "<leader>?k", "<cmd>lua require('telescope.builtin').keymaps()<cr>", { desc = "Keymaps" })
	map("n", "<leader>?c", "<cmd>lua require('telescope.builtin').commands()<cr>", { desc = "Commands" })
	map("n", "<leader>?a", "<cmd>lua require('telescope.builtin').autocommands()<cr>", { desc = "Autocommands" })
	map("n", "<leader>?g", "<cmd>lua require('telescope.builtin').highlights()<cr>", { desc = "Highlight groups" })
	map("n", "<leader>?v", "<cmd>lua require('telescope.builtin').vim_options()<cr>", { desc = "Vim options" })
	map("n", "<leader>?n", "<cmd>NoiceHistory<cr>", { desc = "Notifications" })
	map("n", "<leader>?s", "<cmd>Telescope luasnip<CR>", { desc = "Snippets" })
	map("n", "<leader>?S", "<cmd>lua require('luasnip.loaders').edit_snippet_files()<cr>", { desc = "Edit snippets" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Tools                                           ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "<leader>z", "{}", { desc = "Tools" })
	map("n", "<leader>zc", "<cmd>CccPick<cr>", { desc = "Colour picker" })
	map("n", "<leader>zl", "<cmd>Lazy<cr>", { desc = "Lazy" })
	map("n", "<leader>zm", "<cmd>Mason<cr>", { desc = "Mason" })
	map("n", "<leader>zs", "<cmd>StartupTime<cr>", { desc = "StartupTime" })
	map("n", "<leader>zr", "<cmd>luafile %<CR>", { desc = "Source current file" })
	map("n", "<leader>zo", function()
		require("utils").UI_select({
			ChatGPT = "vim.cmd('ChatGPT')",
			ChatGPTActAs = "vim.cmd('ChatGPTActAs')",
			ChatGPTEditWithInstructions = "vim.cmd('ChatGPTEditWithInstructions')",
		})
	end, { desc = "ChatGPT" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Mind                                            ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "<leader>m", "<cmd>MindOpenSmartProject<cr>", { desc = "Mind" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Window / Splits                                 ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "<leader>wv", '<cmd>call VSCodeNotify("workbench.action.splitEditorRight")<cr>')
	map("n", "<leader>ws", '<cmd>call VSCodeNotify("workbench.action.splitEditorDown")<cr>')
	map("n", "<leader>wq", '<cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<cr>')

	map("n", "<leader>wh", '<cmd>call VSCodeNotify("workbench.action.focusLeftGroup")<cr>')
	map("n", "<leader>wj", '<cmd>call VSCodeNotify("workbench.action.focusBelowGroup")<cr>')
	map("n", "<leader>wk", '<cmd>call VSCodeNotify("workbench.action.focusAboveGroup")<cr>')
	map("n", "<leader>wl", '<cmd>call VSCodeNotify("workbench.action.focusRightGroup")<cr>')

	map("n", "<leader>wH", '<cmd>call VSCodeNotify("workbench.action.moveEditorToLeftGroup")<cr>')
	map("n", "<leader>wJ", '<cmd>call VSCodeNotify("workbench.action.moveEditorToBelowGroup")<cr>')
	map("n", "<leader>wK", '<cmd>call VSCodeNotify("workbench.action.moveEditorToAboveGroup")<cr>')
	map("n", "<leader>wL", '<cmd>call VSCodeNotify("workbench.action.moveEditorToRightGroup")<cr>')

	map("n", "<leader>wr", '<cmd>call VSCodeNotify("workbench.action.increaseViewSize")<cr>')
	map("n", "<leader>wR", '<cmd>call VSCodeNotify("workbench.action.decreaseViewSize")<cr>')
else
	map("n", "<leader>wq", "<C-W>q", { desc = "Close split" })
	map("n", "<leader>ww", "<cmd>WindowsMaximizeHorizontally<cr>", { desc = "Maximize window" })

	map("n", "<leader>wh", "<cmd>lua require('utils').move_create_split('h')<cr>", { desc = "Focus left" })
	map("n", "<leader>wj", "<cmd>lua require('utils').move_create_split('j')<cr>", { desc = "Focus down" })
	map("n", "<leader>wk", "<cmd>lua require('utils').move_create_split('k')<cr>", { desc = "Focus up" })
	map("n", "<leader>wl", "<cmd>lua require('utils').move_create_split('l')<cr>", { desc = "Focus right" })

	map("n", "<leader>wH", "<C-W>H", { desc = "Move left" })
	map("n", "<leader>wJ", "<C-W>J", { desc = "Move down" })
	map("n", "<leader>wK", "<C-W>K", { desc = "Move up" })
	map("n", "<leader>wL", "<C-W>L", { desc = "Move right" })

	map("n", "<leader>w<up>", ":resize +15<cr>") -- FIXME: fix the direction on these
	map("n", "<leader>w<down>", ":resize -15<cr>")
	map("n", "<leader>w<left>", ":vertical resize -15<cr>")
	map("n", "<leader>w<right>", ":vertical resize +15<cr>")
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Buffers                                         ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "[b", '<cmd>call VSCodeNotify("workbench.action.previousEditor")<cr>')
	map("n", "]b", '<cmd>call VSCodeNotify("workbench.action.nextEditor")<cr>')
	map("n", "<leader>bq", '<cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<cr>')
	map("n", "<leader>bp", '<cmd>call VSCodeNotify("workbench.action.pinEditor")<cr>')
else
	map("n", "<leader>bb", "<cmd>BufferLinePick<cr>", { desc = "Pick" })
	map("n", "<leader>bq", "<cmd>bdelete<cr>", { desc = "Close" })
	map("n", "<leader>bQ", function()
		local cur_buf = vim.fn.bufnr()
		for _, e in ipairs(require("bufferline").get_elements().elements) do
			vim.schedule(function()
				if e.id ~= cur_buf then
					vim.cmd("bd " .. e.id)
				end
			end)
		end
	end, { desc = "Close others" })
	map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin" })
	map("n", "<leader>bf", "<cmd>lua require('telescope.builtin').buffers()<cr>", { desc = "Find" })
	map("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
	map("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
	map("n", "<leader>bl", "<cmd>BufferLineMoveNext<cr>", { desc = "Move Next" })
	map("n", "<leader>bh", "<cmd>BufferLineMovePrev<cr>", { desc = "Move Prev" })
	map("n", "<leader>b1", "<cmd>lua require('bufferline').go_to_buffer(1, true)<cr>", { desc = "Buffer 1" })
	map("n", "<leader>b2", "<cmd>lua require('bufferline').go_to_buffer(2, true)<cr>", { desc = "Buffer 2" })
	map("n", "<leader>b3", "<cmd>lua require('bufferline').go_to_buffer(3, true)<cr>", { desc = "Buffer 3" })
	map("n", "<leader>b4", "<cmd>lua require('bufferline').go_to_buffer(4, true)<cr>", { desc = "Buffer 4" })
	map("n", "<leader>b5", "<cmd>lua require('bufferline').go_to_buffer(5, true)<cr>", { desc = "Buffer 5" })
	map("n", "<leader>b6", "<cmd>lua require('bufferline').go_to_buffer(6, true)<cr>", { desc = "Buffer 6" })
	map("n", "<leader>b7", "<cmd>lua require('bufferline').go_to_buffer(7, true)<cr>", { desc = "Buffer 7" })
	map("n", "<leader>b8", "<cmd>lua require('bufferline').go_to_buffer(8, true)<cr>", { desc = "Buffer 8" })
	map("n", "<leader>b9", "<cmd>lua require('bufferline').go_to_buffer(9, true)<cr>", { desc = "Buffer 9" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Folds                                           ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "zR", "<cmd>lua require('ufo').openAllFolds()<cr>", { desc = "Open all folds" })
	map("n", "zM", "<cmd>lua require('ufo').closeAllFolds)<cr>", { desc = "Close all folds" })
	map("n", "zr", "<cmd>lua require('ufo').openFoldsExceptKinds()<cr>", { desc = "Open folds except kinds" })
	map("n", "zm", "<cmd>lua require('ufo').closeFoldsWithKinds()<cr>", { desc = "Close folds with kinds" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Find                                            ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "<leader>ff", '<cmd>call VSCodeNotify("workbench.action.findInFiles")<cr>')
	map("n", "<leader>fr", '<cmd>call VSCodeNotify("workbench.action.openRecent")<cr>')
	map("n", "<leader>fs", '<cmd>call VSCodeNotify("editor.action.selectHighlights")<cr>')
	map("n", "<leader>fp", '<cmd>call VSCodeNotify("projectManager.listProjects")<cr>')
	map("n", "<leader>fn", '<cmd>call VSCodeNotify("workbench.files.action.showActiveFileInExplorer")<cr>')
else
	map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", { desc = "Files" })
	map("n", "<leader>fg", "<cmd>lua require('utils').live_grep_from_project_git_root()<cr>", { desc = "Grep" })
	map("n", "<leader>fr", "<cmd>lua require('telescope.builtin').oldfiles()<cr>", { desc = "Recent" })
	map("n", "<leader>fs", "<cmd>lua require('telescope.builtin').grep_string()<cr>", { desc = "String" })
	map("n", "<leader>fp", "<cmd>lua require('telescope').extensions.projects.projects({})<cr>", { desc = "Project" })
	map(
		"n",
		"<leader>fn",
		"<cmd>Neotree position=float reveal=true reveal_force_cwd=false toggle=true<cr>",
		{ desc = "Tree" }
	)
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Leap                                            ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x", "o" }, "s", "<Plug>(leap-forward-to)", { desc = "Leap forward" })
map({ "n", "x", "o" }, "S", "<Plug>(leap-backward-to)", { desc = "Leap backward" })
map({ "n", "x", "o" }, "<leader>s", "<Plug>(leap-from-window)", { desc = "Leap window" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Go to                                           ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
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
	map("n", "<leader>gh", show_hover, { desc = "Hover" }) -- must be mapped outside function otherwise filetypes without LSP won't get the bind

	function MapLSP(bufnr)
		map("n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { desc = "Declaration", buffer = bufnr })
		map("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Definition", buffer = bufnr })
		map(
			"n",
			"<leader>gt",
			"<cmd>lua vim.lsp.buf.type_definition()<cr>",
			{ desc = "Type Definition", buffer = bufnr }
		)
		map(
			"n",
			"<leader>gr",
			"<cmd>lua vim.lsp.buf.references()<cr>",
			{ desc = "Find all references", buffer = bufnr }
		)
		map("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", { desc = "Implementation", buffer = bufnr })
		map("n", "<leader>gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", { desc = "Signature", buffer = bufnr })
		map("n", "<leader>ge", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Show Error", buffer = bufnr })
		map("n", "<leader>gE", "<cmd>TroubleToggle<cr>", { desc = "Error List", buffer = bufnr })

		map("n", "[e", "<cmd>lua vim.diagnostic.goto_prev()<cr>", { desc = "Previous error", buffer = bufnr })
		map("n", "]e", "<cmd>lua vim.diagnostic.goto_next()<cr>", { desc = "Next error", buffer = bufnr })

		-- Binds that dont belong under "g" but should only be set when LSP is attached
		map("n", "<leader>rr", "<cmd>lua vim.lsp.buf.rename()<cr>", { desc = "LSP Rename" })
		map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "Code Action", buffer = bufnr })
	end
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Code                                            ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "<leader>co", '<cmd>call VSCodeNotify("outline.focus")<cr>')
else
	map("n", "<Leader>cd", ":lua require('neogen').generate()<CR>", { desc = "Generate docs" })
	map("n", "<leader>cf", "<cmd>NullFormat<cr>", { desc = "Format" })
	map("n", "<leader>co", "<cmd>AerialToggle!<cr>", { desc = "Aerial Outline" })
	map("n", "<leader>cs", "<cmd>TSJSplit<cr>", { desc = "Split line" })
	map("n", "<leader>cj", "<cmd>TSJJoin<cr>", { desc = "Join line" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Refactoring                                     ║
-- ╚═════════════════════════════════════════════════╝
map(
	"v",
	"<leader>rf",
	[[ <Esc><cmd>lua require('refactoring').refactor('Extract Function')<cr>]],
	{ desc = "Extract to a function", expr = false }
)
map(
	"v",
	"<leader>rv",
	[[ <Esc><cmd>lua require('refactoring').refactor('Extract Variable')<cr>]],
	{ desc = "Extract to a variable", expr = false }
)
map(
	"n",
	"<leader>ri",
	[[ <cmd>lua require('refactoring').refactor('Inline Variable')<cr>]],
	{ desc = "Inline a variable", expr = false }
)
map(
	"n",
	"<leader>rpf",
	":lua require('refactoring').debug.printf({below = false})<cr>",
	{ desc = "Add print statement (function)" }
)
map(
	"n",
	"<leader>rpv",
	":lua require('refactoring').debug.print_var({ normal = true })<cr>",
	{ desc = "Add print statement (variable)" }
)
map("n", "<leader>rpc", ":lua require('refactoring').debug.cleanup({})<cr>", { desc = "Cleanup print statements" })

map("n", "<leader>R", "<CMD>SearchReplaceSingleBufferCWord<CR>", { desc = "Search and replace" })
map("v", "<leader>R", "<CMD>SearchReplaceSingleBufferVisualSelection<CR>", { desc = "Search and replace" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Snippets                                        ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
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
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Yanky                                           ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map({ "n", "x" }, "<leader>y", "<cmd>Telescope yank_history<cr>", { desc = "Yanks " })
	map({ "n", "x" }, "y", "<Plug>(YankyYank)")
	map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
	map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
	map("n", "<c-n>", "<Plug>(YankyCycleForward)")
	map("n", "<c-p>", "<Plug>(YankyCycleBackward)")
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Terminal                                        ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "<leader>`", '<cmd>call VSCodeNotify("workbench.action.terminal.toggleTerminal")<cr>')
else
	map("n", "<leader>`", "<cmd>ToggleTerm<cr>", { desc = "Terminal" })
	map("t", "<esc>", "<C-\\><C-n>") -- Escape to normal mode in terminal
end

-- ╔═════════════════════════════════════════════════╗
-- ║ DAP / Debug                                     ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "<f5>", "<cmd>lua require('dap').continue()<cr>", { desc = "Continue" })
	map("n", "<f6>", "<cmd>lua require('dap').step_over()<cr>", { desc = "Step over" })
	map("n", "<f7>", "<cmd>lua require('dap').step_into()<cr>", { desc = "Step into" })
	map("n", "<f8>", "<cmd>lua require('dap').toggle_breakpoint()<cr>", { desc = "Toggle breakpoint" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Git                                             ║
-- ╚═════════════════════════════════════════════════╝
if vscode then
	map("n", "<leader>Gg", '<cmd>call VSCodeNotify("workbench.view.scm")<cr>')
else
	map("n", "<leader>Gg", "<cmd>lua require('utils').toggle_lazygit()<cr>", { desc = "Git" })
	map("n", "<leader>Gd", "<cmd>lua require('gitsigns').diffthis()<cr>", { desc = "Diff" })
	map("n", "<leader>Gh", "<cmd>lua require('gitsigns').preview_hunk()<cr>", { desc = "Hover hunk" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Overseer                                        ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "<c-f5>", "<cmd>OverseerRun<cr>", { desc = "Overseer Run" })
	map("n", "<s-f5>", "<cmd>OverseerToggle<cr>", { desc = "Overseer List" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Todo                                            ║
-- ╚═════════════════════════════════════════════════╝
if not vscode then
	map("n", "<leader>t", "<cmd>TodoTelescope<cr>", { desc = "Todo list" })
	map("n", "]t", function()
		require("todo-comments").jump_next()
	end, { desc = "Next todo comment" })

	map("n", "[t", function()
		require("todo-comments").jump_prev()
	end, { desc = "Previous todo comment" })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Jupynium                                        ║
-- ╚═════════════════════════════════════════════════╝
-- TODO: create buffer local maps for these either in config or with autocommands
if not vscode then
	local tag_code = "# %%"
	local tag_md = "# %% [md]"

	local function go_to_end_of_cell()
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
		vim.cmd("startinsert")
	end

	local function insert_below(tag)
		go_to_end_of_cell()

		vim.cmd("call append(line('.'), '')")
		vim.cmd("call append(line('.'), '')")
		vim.cmd("call append(line('.'), '')")
		vim.api.nvim_buf_set_lines(0, vim.fn.line("."), vim.fn.line(".") + 1, false, { tag })
		vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") + 2, 0 })
		vim.cmd("startinsert")
	end

	local function insert_md_quotes()
		vim.cmd("call append(line('.'), '')")
		vim.cmd("call append(line('.'), '')")
		vim.api.nvim_buf_set_lines(0, vim.fn.line(".") - 1, vim.fn.line("."), false, { '"""' })
		vim.api.nvim_buf_set_lines(0, vim.fn.line(".") + 1, vim.fn.line(".") + 2, false, { '"""' })
		vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") + 1, 0 })
		vim.cmd("startinsert")
	end

	map({ "n", "x" }, "<leader>jac", function()
		insert_above(tag_code)
	end, { desc = "Insert code cell above" })
	map({ "n", "x" }, "<leader>jam", function()
		insert_above(tag_md)
		insert_md_quotes()
	end, { desc = "Insert markdown cell above" })

	map({ "n", "x" }, "<leader>jbc", function()
		insert_below(tag_code)
	end, { desc = "Insert code cell below" })
	map({ "n", "x" }, "<leader>jbm", function()
		insert_below(tag_md)
		insert_md_quotes()
	end, { desc = "Insert markdown cell below" })

	map({ "n", "x" }, "<leader>jS", "<cmd>JupyniumStartAndAttachToServer<cr>", { desc = "Start Jupynium server" })
	map({ "n", "x" }, "<leader>js", "<cmd>JupyniumStartSync<cr>", { desc = "Sync Jupynium" })
	map({ "n", "x" }, "<leader>jh", "<cmd>JupyniumKernelHover<cr>", { desc = "Hover" })
	map({ "n", "x" }, "<leader>jkr", "<cmd>JupyniumKernelRestart<cr>", { desc = "Restart kernel" })
	map({ "n", "x" }, "<leader>jks", "<cmd>JupyniumKernelSelect<cr>", { desc = "Select kernel" })
	map({ "n", "x" }, "<leader>jki", "<cmd>JupyniumKernelInterrupt<cr>", { desc = "Interrupt kernel" })
	map(
		{ "n", "x", "o" },
		"<leader>jj",
		"<cmd>lua require'jupynium.textobj'.goto_current_cell_separator()<cr>",
		{ desc = "Go to current cell" }
	)
	map({ "n", "x" }, "<leader>je", "<cmd>JupyniumExecuteSelectedCells<cr>", { desc = "Execute cell" })
	map({ "n", "x" }, "<leader>jE", "ggVG<cmd>JupyniumExecuteSelectedCells<cr><esc>", { desc = "Execute all cells" }) -- TODO: jump back to prev cursor location
	map({ "n", "x" }, "<leader>joc", "<cmd>JupyniumClearSelectedCellsOutputs<cr>", { desc = "Clear output" })
	map({ "n", "x" }, "<leader>jot", "<cmd>JupyniumToggleSelectedCellsOutputsScroll<cr>", { desc = "Toggle output" })

	-- text objects
	map(
		{ "n", "x", "o" },
		"[j",
		"<cmd>lua require'jupynium.textobj'.goto_previous_cell_separator()<cr>",
		{ desc = "Previous jupyter cell" }
	)
	map(
		{ "n", "x", "o" },
		"]j",
		"<cmd>lua require'jupynium.textobj'.goto_next_cell_separator()<cr>",
		{ desc = "Next jupyter cell" }
	)
	map(
		{ "x", "o" },
		"aj",
		"<cmd>lua require'jupynium.textobj'.select_cell(true, false)<cr>",
		{ desc = "Around jupyter cell" }
	)
	map(
		{ "x", "o" },
		"ij",
		"<cmd>lua require'jupynium.textobj'.select_cell(false, false)<cr>",
		{ desc = "Inside jupyter cell" }
	)
end
