-- set default Todo HL to same as Comment (plugins can use their own HL group for Todo:)
vim.api.nvim_set_hl(0, "Todo", { link = "Comment" })

-- link neotree colours to nvim-tree for automatic theme support
-- https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Visual-Customizations#colour-scheme
vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { link = "NvimTreeFolderIcon" })
vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { link = "NvimTreeOpenedFolderName" })
vim.api.nvim_set_hl(0, "NeoTreeSymbolicLinkTarget", { link = "NvimTreeSymlink" })
vim.api.nvim_set_hl(0, "NeoTreeRootName", { link = "NvimTreeRootFolder" })
vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { link = "NvimTreeOpenedFile" })

-- linked groups for all themes
vim.api.nvim_set_hl(0, "TroubleCount", { link = "DiagnosticOk" })
vim.api.nvim_set_hl(0, "TroubleTextHint", { link = "DiagnosticHint" })
vim.api.nvim_set_hl(0, "TroubleTextError", { link = "DiagnosticError" })
vim.api.nvim_set_hl(0, "TroubleTextWarning", { link = "DiagnosticWarn" })
vim.api.nvim_set_hl(0, "TroubleTextInformation", { link = "DiagnosticInfo" })

local C = {}

-- local function set_theme_colours(theme)
--   local colors = require("kanagawa.colors").setup()
--   local theme_colors = colors.palette
--   C.normal = theme_colors.roninYellow
--   C.insert = theme_colors.autumnRed
--   C.visual = theme_colors.autumnGreen
--   C.command = theme_colors.roninYellow
--   C.replace = theme_colors.autumnRed
--   C.comment = theme_colors.fujiGray
--   C.overlay = theme_colors.crystalBlue
--   C.sep = theme_colors.fujiGray
--   C.status = "#282A2E"
--   C.status_icon = { fg = theme_colors.fujiWhite, bg = theme_colors.dragonBlue }
--   C.text = theme_colors.fujiGray
--   C.textDark = theme_colors.sumiInk0
--   C.textLight = theme_colors.fujiWhite
--   C.bufPick = theme_colors.autumnRed
--   C.bufSelected = theme_colors.fujiWhite
--   C.bufVisible = theme_colors.dragonBlue
--   C.bufModified = theme_colors.springGreen
--   C.bufClose = theme_colors.autumnRed
-- end

-- local current_theme = vim.api.nvim_exec("color", true)
-- set_theme_colours(current_theme)

return C
