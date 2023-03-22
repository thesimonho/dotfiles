local utils = require("utils")
local map = utils.map

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
	"<cmd>lua require('refactoring').debug.printf({below = false})<cr>",
	{ desc = "Add print statement (function)" }
)
map(
	"n",
	"<leader>rpv",
	"<cmd>lua require('refactoring').debug.print_var({ normal = true })<cr>",
	{ desc = "Add print statement (variable)" }
)
map("n", "<leader>rpc", "<cmd>lua require('refactoring').debug.cleanup({})<cr>", { desc = "Cleanup print statements" })

map("n", "<leader>R", "<CMD>SearchReplaceSingleBufferCWord<CR>", { desc = "Search and replace" })
map("v", "<leader>R", "<CMD>SearchReplaceSingleBufferVisualSelection<CR>", { desc = "Search and replace" })
