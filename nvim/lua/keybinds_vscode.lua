local utils = require("utils")
local map = utils.map

-- ╔═════════════════════════════════════════════════╗
-- ║ Window / Splits                                 ║
-- ╚═════════════════════════════════════════════════╝
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

-- ╔═════════════════════════════════════════════════╗
-- ║ Buffers                                         ║
-- ╚═════════════════════════════════════════════════╝
map("n", "[b", '<cmd>call VSCodeNotify("workbench.action.previousEditor")<cr>')
map("n", "]b", '<cmd>call VSCodeNotify("workbench.action.nextEditor")<cr>')
map("n", "<leader>bq", '<cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<cr>')
map("n", "<leader>bp", '<cmd>call VSCodeNotify("workbench.action.pinEditor")<cr>')

-- ╔═════════════════════════════════════════════════╗
-- ║ Find                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>ff", '<cmd>call VSCodeNotify("workbench.action.findInFiles")<cr>')
map("n", "<leader>fr", '<cmd>call VSCodeNotify("workbench.action.openRecent")<cr>')
map("n", "<leader>fs", '<cmd>call VSCodeNotify("editor.action.selectHighlights")<cr>')
map("n", "<leader>fp", '<cmd>call VSCodeNotify("projectManager.listProjects")<cr>')
map("n", "<leader>fn", '<cmd>call VSCodeNotify("workbench.files.action.showActiveFileInExplorer")<cr>')

-- ╔═════════════════════════════════════════════════╗
-- ║ Code                                            ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>co", '<cmd>call VSCodeNotify("outline.focus")<cr>')

-- ╔═════════════════════════════════════════════════╗
-- ║ Terminal                                        ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>`", '<cmd>call VSCodeNotify("workbench.action.terminal.toggleTerminal")<cr>')
-- ╔═════════════════════════════════════════════════╗
-- ║ Git                                             ║
-- ╚═════════════════════════════════════════════════╝
map("n", "<leader>G", '<cmd>call VSCodeNotify("workbench.view.scm")<cr>')
