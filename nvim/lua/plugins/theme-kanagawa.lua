-- Remember to run :KanagawaCompile after editing
-- https://github.com/rebelot/kanagawa.nvim

local M = {
  "rebelot/kanagawa.nvim",
  enabled = true,
}

function M.config()
  local wave = require("kanagawa.colors").setup({ theme = "wave" }) -- borrow colours from wave theme
  local wave_theme = wave.theme
  local palette = wave.palette

  require("kanagawa").setup({
    compile = false,
    undercurl = true,
    dimInactive = true, -- dim inactive window `:h hl-NormalNC`
    commentStyle = { italic = true }, -- comments
    functionStyle = { italic = false }, -- names of functions
    keywordStyle = { italic = false, bold = false }, -- language keywords (e.g. function, local, etc.)
    statementStyle = { italic = false, bold = false },
    typeStyle = { italic = false }, -- type hints/declarations
    terminalColors = true,
    colors = {
      palette = {},
      theme = {
        wave = {},
        lotus = {},
        dragon = {
          ui = { -- use wave theme colors
            fg = wave_theme.ui.fg,
            fg_dim = wave_theme.ui.fg_dim,
            fg_reverse = wave_theme.ui.fg_reverse,

            bg_dim = wave_theme.ui.bg_dim,
            bg_m3 = wave_theme.ui.bg_m3,
            bg_m2 = wave_theme.ui.bg_m2,
            bg_m1 = wave_theme.ui.bg_m1,
            bg = wave_theme.ui.bg,
            bg_p1 = wave_theme.ui.bg_p1,
            bg_p2 = wave_theme.ui.bg_p2,

            special = wave_theme.ui.special,
            nontext = wave_theme.ui.nontext,
            whitespace = wave_theme.ui.whitespace,

            bg_search = wave_theme.ui.bg_search,
            bg_visual = wave_theme.ui.bg_visual,

            pmenu = {
              fg = wave_theme.ui.shade0,
              bg = wave_theme.ui.bg_p1,
              bg_sel = wave_theme.diff.text,
              bg_sbar = wave_theme.ui.bg_m1,
              bg_thumb = wave_theme.ui.bg_p2,
            },
            float = {
              fg = wave_theme.ui.float.fg,
              bg = wave_theme.ui.bg_p2,
              fg_border = wave_theme.ui.float.fg_border,
              bg_border = wave_theme.ui.bg,
            },
          },
          syn = { comment = wave_theme.syn.comment },
        },
        all = { ui = { bg_gutter = "none", pmenu = { fg_sel = "none" } } },
      },
    },
    overrides = function(colors) -- add/modify highlights
      HoverBG = colors.theme.ui.bg_p1

      return {
        LazyNormal = { bg = HoverBG, fg = colors.theme.ui.fg_dim },
        MasonNormal = { bg = HoverBG, fg = colors.theme.ui.fg_dim },
        DiagnosticVirtualTextError = { fg = colors.palette.samuraiRed },
        DiagnosticVirtualTextWarn = { fg = colors.palette.roninYellow },
        DiagnosticVirtualTextInfo = { fg = colors.palette.waveAqua1 },
        DiagnosticVirtualTextHint = { fg = colors.palette.dragonBlue },
        WinSeparator = { fg = colors.palette.dragonBlue },
        IblIndent = { fg = colors.palette.sumiInk4 },

        BufferlineIndicatorSelected = { fg = colors.palette.dragonBlue },
        BufferlineModified = { fg = colors.palette.dragonOrange },
        BufferlineModifiedSelected = { fg = colors.palette.dragonOrange },
        BufferlineTabSelected = { bg = colors.theme.ui.bg_p1, fg = colors.palette.fujiWhite },
        BufferlineTabClose = { fg = colors.palette.dragonRed },
        BufferlineCloseButtonSelected = { fg = colors.palette.dragonRed },

        InclineNormal = { bg = colors.palette.fujiWhite, fg = colors.theme.ui.bg_dim },
        InclineNormalNC = { bg = colors.theme.ui.bg_p2, fg = colors.palette.fujiWhite },

        RainbowDelimiterRed = { fg = colors.theme.ui.fg },
        RainbowDelimiterYellow = { fg = colors.palette.dragonRed },
        RainbowDelimiterBlue = { fg = colors.palette.dragonBlue },
        RainbowDelimiterOrange = { fg = colors.palette.dragonOrange },
        RainbowDelimiterGreen = { fg = colors.palette.dragonGreen },
        RainbowDelimiterViolet = { fg = colors.palette.dragonViolet },
        RainbowDelimiterCyan = { fg = colors.palette.dragonTeal },

        NvimTreeRootFolder = { fg = colors.palette.autumnRed },
        NvimTreeOpenedFolderName = { fg = colors.palette.dragonBlue },
        NeoTreeGitConflict = { italic = false, fg = colors.palette.roninYellow },
        NeoTreeGitUntracked = { link = "NeoTreeGitConflict" },
        NeoTreeIndentMarker = { link = "IblIndent" },
        NeoTreeWinSeparator = { fg = colors.theme.ui.bg_dim, bg = colors.theme.ui.bg_dim },

        TelescopeTitle = { fg = colors.palette.sumiInk0, bg = colors.palette.dragonBlue, bold = true },
        TelescopeSelection = { bg = colors.palette.winterYellow },
        TelescopePromptNormal = { bg = colors.theme.ui.bg_p2 },
        TelescopePromptBorder = { fg = colors.theme.ui.bg_p2, bg = colors.theme.ui.bg_p2 },
        TelescopeResultsNormal = { fg = colors.palette.fujiWhite, bg = HoverBG },
        TelescopeResultsBorder = { fg = HoverBG, bg = HoverBG },
        TeleScopePreviewTitle = { fg = colors.palette.sumiInk0, bg = colors.palette.waveAqua1, bold = true },
        TelescopePreviewNormal = { bg = colors.theme.ui.bg },
        TelescopePreviewBorder = { bg = colors.theme.ui.bg, fg = colors.theme.ui.bg },

        WhichKey = { fg = colors.palette.peachRed },
        WhichKeySeparater = { fg = colors.palette.dragonGray2, italic = false },
        WhichKeyFloat = { bg = HoverBG },
        WhichKeyBorder = { bg = HoverBG },

        YankyYanked = { bg = colors.palette.winterYellow },
        YankyPut = { bg = colors.palette.winterRed },
      }
    end,
    background = { -- set theme based on background color
      dark = "dragon",
      light = "lotus",
    },
  })

  -- load the colorscheme after config
  vim.cmd([[colorscheme kanagawa]])
end

return M
