local C = {}

local function set_theme_colours()
  local theme_colors = require("kanagawa-paper.colors").palette

  C.palette = theme_colors
  C.command = theme_colors.roninYellow
  C.normal = theme_colors.roninYellow
  C.insert = theme_colors.autumnRed
  C.insertBG = theme_colors.winterRed
  C.visual = theme_colors.dragonBlue
  C.replace = theme_colors.autumnRed
  C.yank = theme_colors.dragonOrange
  C.comment = theme_colors.fujiGray
  C.overlay = theme_colors.crystalBlue
  C.sep = theme_colors.fujiGray
  C.cursorLine = theme_colors.sumiInk5
  C.status = theme_colors.dragonBlack4
  C.status_icon = { fg = theme_colors.fujiWhite, bg = theme_colors.dragonBlue }
  C.text = theme_colors.fujiGray
  C.textDark = theme_colors.sumiInk0
  C.textLight = theme_colors.fujiWhite
  C.bufPick = theme_colors.autumnRed
  C.bufSelected = theme_colors.fujiWhite
  C.bufVisible = theme_colors.dragonBlue
  C.bufModified = theme_colors.springGreen
  C.bufClose = theme_colors.autumnRed
end

-- set_theme_colours()

return C
