local utils = require("utils")
local map = utils.map

-- ╔═════════════════════════════════════════════════╗
-- ║ General                                         ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>qq", "<cmd>qa<cr>") -- Quit all windows
map({ "n", "i", "x" }, "<C-S>", "<Cmd>silent! update | redraw<CR>", { desc = "Save" })
map("n", "<esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" }) -- Clear highlights on ESC
map("n", "<c-p>", "<cmd>lua require('telescope.builtin').keymaps()<cr>", { desc = "Command Palette" })

map("i", "<C-H>", "<C-W>", { desc = "Delete word backward" }) -- Delete word backwards; C-H = C-BS
map("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forward" }) -- Delete word forwards
map("n", "<Tab>", "<C-^>", { desc = "Alternate file" }) -- Switch to previous file

-- ╔═════════════════════════════════════════════════╗
-- ║ Help                                            ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x", "v" }, "<F1><F1>", "<cmd>execute 'h ' . expand('<cword>')<cr>", { desc = "Current word help" })
map({ "n", "x", "v" }, "<F1>h", "<cmd>lua require('telescope.builtin').help_tags()<cr>", { desc = "Search help" })
map({ "n", "x", "v" }, "<F1>c", "<cmd>lua require('telescope.builtin').commands()<cr>", { desc = "Commands" })
map({ "n", "x", "v" }, "<F1>a", "<cmd>lua require('telescope.builtin').autocommands()<cr>", { desc = "Autocommands" })
map({ "n", "x", "v" }, "<F1>g", "<cmd>lua require('telescope.builtin').highlights()<cr>", { desc = "Highlight groups" })
map({ "n", "x", "v" }, "<F1>v", "<cmd>lua require('telescope.builtin').vim_options()<cr>", { desc = "Vim options" })
map({ "n", "x", "v" }, "<F1>n", "<cmd>NoiceHistory<cr>", { desc = "Notifications" })
map({ "n", "x", "v" }, "<F1>m", "<cmd>messages<cr>", { desc = "Messages" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Tools                                           ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>zl", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>zm", "<cmd>Mason<cr>", { desc = "Mason" })
map("n", "<leader>zs", "<cmd>lua require('luasnip.loaders').edit_snippet_files()<cr>", { desc = "Edit snippets" })
map("n", "<leader>zr", "<cmd>luafile %<CR>", { desc = "Source current file" })
map("n", "<leader>zi", "<cmd>Inspect<CR>", { desc = "TS Inspect" })
map("n", "<leader>zI", "<cmd>InspectTree<CR>", { desc = "TS Inspect Tree" })
map("n", "<leader>zpm", "<cmd>MarkdownPreview<cr>", { desc = "Markdown" })
map("n", "<leader>zn", "<cmd>Telescope package_info<cr>", { desc = "npm" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Window / Splits                                 ║
-- ╚═════════════════════════════════════════════════╝

map("n", "<leader>wh", "<cmd>lua require('utils').move_create_split('h')<cr>", { desc = "Focus/split left" })
map("n", "<leader>wj", "<cmd>lua require('utils').move_create_split('j')<cr>", { desc = "Focus/split down" })
map("n", "<leader>wk", "<cmd>lua require('utils').move_create_split('k')<cr>", { desc = "Focus/split up" })
map("n", "<leader>wl", "<cmd>lua require('utils').move_create_split('l')<cr>", { desc = "Focus/split right" })

map("n", "<leader>wH", "<C-W>H", { desc = "Move left" })
map("n", "<leader>wJ", "<C-W>J", { desc = "Move down" })
map("n", "<leader>wK", "<C-W>K", { desc = "Move up" })
map("n", "<leader>wL", "<C-W>L", { desc = "Move right" })

map("n", "<leader>w<up>", "<cmd>resize +15<cr>", { desc = "Resize up" })
map("n", "<leader>w<down>", "<cmd>resize -15<cr>", { desc = "Resize down" })
map("n", "<leader>w<left>", "<cmd>vertical resize +15<cr>", { desc = "Resize left" })
map("n", "<leader>w<right>", "<cmd>vertical resize -15<cr>", { desc = "Resize right" })

map("n", "<leader>wd", "<C-W>c", { desc = "Close" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Buffers                                         ║
-- ╚═════════════════════════════════════════════════╝
-- map("n", "<leader>bc", cmd("BufferLinePickClose"), { desc = "Pick close" })
-- map("n", "<leader>bq", cmd("bp<bar>sp<bar>bn<bar>bd<CR>"), { desc = "Close current" })
-- map("n", "<leader>bQ", function()
-- 	local cur_buf = vim.fn.bufnr()
-- 	for _, e in ipairs(require("bufferline").get_elements().elements) do
-- 		vim.schedule(function()
-- 			if e.id ~= cur_buf then
-- 				vim.cmd("bd " .. e.id)
-- 			end
-- 		end)
-- 	end
-- end, { desc = "Close others" })
-- map("n", "<leader>bp", cmd("BufferLineTogglePin"), { desc = "Pin" })
-- map("n", "[b", cmd("BufferLineCyclePrev"), { desc = "Prev" })
-- map("n", "]b", cmd("BufferLineCycleNext"), { desc = "Next" })
-- map("n", "<leader>bH", cmd("BufferLineMovePrev"), { desc = "Move Prev" })
-- map("n", "<leader>bL", cmd("BufferLineMoveNext"), { desc = "Move Next" })

-- for i = 1, 9 do
-- 	map(
-- 		"n",
-- 		string.format("\\%d", i),
-- 		string.format("<cmd>lua require'bufferline'.go_to(%d)<CR>", i),
-- 		{ desc = string.format("Buffer %d", i) }
-- 	)
-- end

-- ╔═════════════════════════════════════════════════╗
-- ║ Tabs                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>tt", function()
	vim.cmd("tabnew")
	require("telescope").extensions.project.project({})
end, { desc = "New tab" })
map("n", "<leader>tq", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "[t", "<cmd>tabprev<cr>", { desc = "Prev tab" })
map("n", "]t", "<cmd>tabnext<cr>", { desc = "Next tab" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Movement                                        ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x" }, "j", "v:count ? 'j' : 'gj'", { expr = true, desc = "Down" }) -- Move down across wraps
map({ "n", "x" }, "k", "v:count ? 'k' : 'gk'", { expr = true, desc = "Up" }) -- Move up across wraps
map({ "n", "x" }, "gg", "mggg", { desc = "Mark and go to top" }) -- Mark and go to top
map({ "n", "x" }, "G", "mgG", { desc = "Mark and go to bottom" }) -- Mark and go to bottom

map("i", "<M-h>", "<Left>", { noremap = false, desc = "Left" })
map("i", "<M-j>", "<Down>", { noremap = false, desc = "Down" })
map("i", "<M-k>", "<Up>", { noremap = false, desc = "Up" })
map("i", "<M-l>", "<Right>", { noremap = false, desc = "Right" })
map("t", "<M-h>", "<Left>", { desc = "Left" })
map("t", "<M-j>", "<Down>", { desc = "Down" })
map("t", "<M-k>", "<Up>", { desc = "Up" })
map("t", "<M-l>", "<Right>", { desc = "Right" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Search                                          ║
-- ╚═════════════════════════════════════════════════╝
map("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]])
map("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]])
map("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]])
map("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]])
map("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]])
map("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]])

-- ╔═════════════════════════════════════════════════╗
-- ║ Leap                                            ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x", "o" }, "<leader>j", "<Plug>(leap-forward-to)", { desc = "Leap forward" })
map({ "n", "x", "o" }, "<leader>k", "<Plug>(leap-backward-to)", { desc = "Leap backward" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Find                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", { desc = "Files" })
map("n", "<leader>fb", "<cmd>JABSOpen<cr>", { desc = "Buffers" })
map("n", "<leader>fg", "<cmd>lua require('utils').live_grep_from_project_root()<cr>", { desc = "Grep project" })
map("n", "<leader>fr", "<cmd>lua require('telescope.builtin').oldfiles()<cr>", { desc = "Recent" })
map("n", "<leader>fs", "<cmd>lua require('telescope.builtin').grep_string()<cr>", { desc = "String" })
map("n", "<leader>pp", "<cmd>lua require('telescope').extensions.project.project{}<cr>", { desc = "Project" })
map(
	"n",
	"<leader>fd",
	"<cmd>Neotree filesystem focus position=left reveal=true reveal_force_cwd=false<cr>",
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
map("n", "<leader>lh", show_hover, { desc = "Hover" }) -- mapped outside otherwise types w/o LSP won't get the bind

function MapLSP(bufnr)
	map("n", "<leader>lD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { desc = "Declaration", buffer = bufnr })
	map("n", "<leader>ld", "<cmd>TroubleToggle lsp_definitions<cr>", { desc = "Definition", buffer = bufnr })
	map("n", "<leader>lt", "<cmd>TroubleToggle lsp_type_definitions<cr>", { desc = "Type Definition", buffer = bufnr })
	map("n", "<leader>lr", "<cmd>TroubleToggle lsp_references<cr>", { desc = "Find all references", buffer = bufnr })
	map("n", "<leader>li", "<cmd>lua vim.lsp.buf.implementation()<cr>", { desc = "Implementation", buffer = bufnr })
	map("n", "<leader>ls", "<cmd>lua vim.lsp.buf.signature_help()<cr>", { desc = "Signature", buffer = bufnr })
	map("n", "<leader>le", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Show Error", buffer = bufnr })
	map("n", "<leader>lE", "<cmd>TroubleToggle<cr>", { desc = "Error List", buffer = bufnr })

	map("n", "[e", "<cmd>lua vim.diagnostic.goto_prev()<cr>", { desc = "Previous error", buffer = bufnr })
	map("n", "]e", "<cmd>lua vim.diagnostic.goto_next()<cr>", { desc = "Next error", buffer = bufnr })

	-- Binds that dont belong under "g" but should only be set when LSP is attached
	map("n", "<leader>lR", "<cmd>lua vim.lsp.buf.rename()<cr>", { desc = "LSP Rename" })
	map("n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "Code Action", buffer = bufnr })
end

-- ╔═════════════════════════════════════════════════╗
-- ║ Code                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<Leader>cd", "<cmd>lua require('neogen').generate()<CR>", { desc = "Generate docs" })
map("n", "<leader>cf", "<cmd>NullFormat<cr>", { desc = "Format" })
map("n", "<leader>co", "<cmd>AerialToggle<cr>", { desc = "Aerial Outline" })
map("n", "<leader>cq", "<cmd>TroubleToggle quickfix<cr>", { desc = "Quickfix" })
map("n", "<leader>cs", "<cmd>lua MiniSplitjoin.toggle()<cr>", { desc = "Split/join" })
map("n", "<leader>ct", "<cmd>TodoTelescope<cr>", { desc = "TODO" })
map("n", "<leader>cTa", function()
	require("neotest").run.run({ suite = true, strategy = "integrated" })
	require("neotest").summary.open()
end, { desc = "Run all" })
map("n", "<leader>cTt", function()
	require("neotest").run.run({ strategy = "integrated" })
end, { desc = "Run test" })
map("n", "<leader>cTs", function()
	require("neotest").summary.toggle()
end, { desc = "Show summary" })
map("n", "<leader>cTo", function()
	require("neotest").output.open()
end, { desc = "Show output" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Snippets                                        ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "s" }, "<c-j>", function()
	if require("luasnip").expand_or_jumpable() then
		require("luasnip").expand_or_jump()
	end
end, { desc = "Next snippet placeholder" })

map({ "n", "s" }, "<c-k>", function()
	if require("luasnip").jumpable(-1) then
		require("luasnip").jump(-1)
	end
end, { desc = "Previous snippet placeholder" })

map("i", "<c-u>", "<cmd>lua require('luasnip.extras.select_choice')()<cr>", { desc = "Select choice" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Yanky                                           ║
-- ╚═════════════════════════════════════════════════╝
map({ "n", "x" }, "<leader>y", "<cmd>YankyRingHistory<cr>", { desc = "Yanks" })
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
map("t", "<c-q>", "<C-\\><C-n>") -- Back to normal mode in terminal
map("t", "kj", "<C-\\><C-n>")

-- ╔═════════════════════════════════════════════════╗
-- ║ Git                                             ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>G", "<cmd>lua require('utils').toggle_lazygit()<cr>", { desc = "Lazygit" })

-- ╔═════════════════════════════════════════════════╗
-- ║ Overseer                                        ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<f5>", "<cmd>OverseerToggle<cr>", { desc = "Overseer List" })
map("n", "<c-f5>", "<cmd>OverseerRun<cr>", { desc = "Overseer Run" })
