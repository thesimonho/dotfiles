-- https://github.com/rebelot/kanagawa.nvim

local M = {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  palette = {
    -- Bg Shades
    sumiInk0 = "#16161D",
    sumiInk1 = "#181820",
    sumiInk2 = "#1a1a22",
    sumiInk3 = "#1F1F28",
    sumiInk4 = "#2A2A37",
    sumiInk5 = "#363646",
    sumiInk6 = "#54546D", --fg

    -- Popup and Floats
    waveBlue1 = "#223249",
    waveBlue2 = "#2D4F67",

    -- Diff and Git
    winterGreen = "#2B3328",
    winterYellow = "#49443C",
    winterRed = "#43242B",
    winterBlue = "#252535",
    autumnGreen = "#76946A",
    autumnRed = "#C34043",
    autumnYellow = "#DCA561",

    -- Diag
    samuraiRed = "#E82424",
    roninYellow = "#FF9E3B",
    waveAqua1 = "#6A9589",
    dragonBlue = "#658594",

    -- Fg and Comments
    oldWhite = "#C8C093",
    fujiWhite = "#DCD7BA",
    fujiGray = "#727169",

    oniViolet = "#957FB8",
    oniViolet2 = "#b8b4d0",
    crystalBlue = "#7E9CD8",
    springViolet1 = "#938AA9",
    springViolet2 = "#9CABCA",
    springBlue = "#7FB4CA",
    lightBlue = "#A3D4D5", -- unused yet
    waveAqua2 = "#7AA89F", -- improve lightness: desaturated greenish Aqua

    -- waveAqua2  = "#68AD99",
    -- waveAqua4  = "#7AA880",
    -- waveAqua5  = "#6CAF95",
    -- waveAqua3  = "#68AD99",

    springGreen = "#98BB6C",
    boatYellow1 = "#938056",
    boatYellow2 = "#C0A36E",
    carpYellow = "#E6C384",

    sakuraPink = "#D27E99",
    waveRed = "#E46876",
    peachRed = "#FF5D62",
    surimiOrange = "#FFA066",
    katanaGray = "#717C7C",

    dragonBlack0 = "#0d0c0c",
    dragonBlack1 = "#12120f",
    dragonBlack2 = "#1D1C19",
    dragonBlack3 = "#181616",
    dragonBlack4 = "#282727",
    dragonBlack5 = "#393836",
    dragonBlack6 = "#625e5a",

    dragonWhite = "#c5c9c5",
    dragonGreen = "#87a987",
    dragonGreen2 = "#8a9a7b",
    dragonPink = "#a292a3",
    dragonOrange = "#b6927b",
    dragonOrange2 = "#b98d7b",
    dragonGray = "#a6a69c",
    dragonGray2 = "#9e9b93",
    dragonGray3 = "#7a8382",
    dragonBlue2 = "#8ba4b0",
    dragonViolet = "#8992a7",
    dragonRed = "#c4746e",
    dragonAqua = "#8ea4a2",
    dragonAsh = "#737c73",
    dragonTeal = "#949fb5",
    dragonYellow = "#c4b28a", --"#a99c8b", -- "#8a9aa3",

    lotusInk1 = "#545464",
    lotusInk2 = "#43436c",
    lotusGray = "#dcd7ba",
    lotusGray2 = "#716e61",
    lotusGray3 = "#8a8980",
    lotusWhite0 = "#d5cea3",
    lotusWhite1 = "#dcd5ac",
    lotusWhite2 = "#e5ddb0",
    lotusWhite3 = "#f2ecbc",
    lotusWhite4 = "#e7dba0",
    lotusWhite5 = "#e4d794",
    lotusViolet1 = "#a09cac",
    lotusViolet2 = "#766b90",
    lotusViolet3 = "#c9cbd1",
    lotusViolet4 = "#624c83",
    lotusBlue1 = "#c7d7e0",
    lotusBlue2 = "#b5cbd2",
    lotusBlue3 = "#9fb5c9",
    lotusBlue4 = "#4d699b",
    lotusBlue5 = "#5d57a3",
    lotusGreen = "#6f894e",
    lotusGreen2 = "#6e915f",
    lotusGreen3 = "#b7d0ae",
    lotusPink = "#b35b79",
    lotusOrange = "#cc6d00",
    lotusOrange2 = "#e98a00",
    lotusYellow = "#77713f",
    lotusYellow2 = "#836f4a",
    lotusYellow3 = "#de9800",
    lotusYellow4 = "#f9d791",
    lotusRed = "#c84053",
    lotusRed2 = "#d7474b",
    lotusRed3 = "#e82424",
    lotusRed4 = "#d9a594",
    lotusAqua = "#597b75",
    lotusAqua2 = "#5e857a",
    lotusTeal1 = "#4e8ca2",
    lotusTeal2 = "#6693bf",
    lotusTeal3 = "#5a7785",
    lotusCyan = "#d7e3d8",
  },
}

function M.config()
  local wave = require("kanagawa.colors").setup({ theme = "wave" }) -- borrow colours from wave theme
  local wave_theme = wave.theme

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
              fg = wave_theme.ui.pmenu.fg,
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
      IndentLine = colors.palette.sumiInk4
      Modified = colors.palette.dragonOrange2

      return {
        LazyNormal = { bg = HoverBG, fg = colors.theme.ui.fg_dim },
        MasonNormal = { bg = HoverBG, fg = colors.theme.ui.fg_dim },
        WinSeparator = { fg = colors.palette.dragonBlue },
        Visual = { bg = colors.palette.waveBlue2, fg = colors.palette.fujiWhite },

        DiagnosticVirtualTextError = { fg = colors.palette.samuraiRed },
        DiagnosticVirtualTextWarn = { fg = colors.palette.roninYellow },
        DiagnosticVirtualTextInfo = { fg = colors.palette.waveAqua1 },
        DiagnosticVirtualTextHint = { fg = colors.palette.dragonBlue },

        BufferlineBufferSelected = { fg = colors.palette.dragonWhite, bold = true },
        BufferlineIndicatorSelected = { fg = colors.palette.dragonBlue },
        BufferlineModified = { fg = Modified },
        BufferlineModifiedSelected = { fg = Modified },
        BufferlineTabSelected = { bg = colors.theme.ui.bg_p1, fg = colors.palette.dragonWhite },
        BufferlineTabClose = { fg = colors.palette.dragonRed },
        BufferlineCloseButtonSelected = { fg = colors.palette.dragonRed },

        RainbowDelimiterRed = { fg = colors.palette.dragonRed },
        RainbowDelimiterYellow = { fg = colors.palette.dragonYellow },
        RainbowDelimiterBlue = { fg = colors.palette.dragonBlue },
        RainbowDelimiterOrange = { fg = colors.palette.dragonOrange2 },
        RainbowDelimiterGreen = { fg = colors.palette.dragonGreen },
        RainbowDelimiterViolet = { fg = colors.palette.dragonAsh },
        RainbowDelimiterCyan = { fg = colors.palette.dragonTeal },

        NvimTreeRootFolder = { fg = colors.palette.autumnRed },
        NvimTreeOpenedFolderName = { fg = colors.palette.dragonBlue },
        NeoTreeGitConflict = { italic = false, fg = colors.palette.roninYellow },
        NeoTreeGitUntracked = { link = "NeoTreeGitConflict" },
        NeoTreeIndentMarker = { fg = IndentLine },
        NeoTreeModified = { fg = Modified },
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

        ScrollView = { bg = colors.palette.sumiInk5 },
        ScrollViewCursor = { fg = colors.palette.dragonOrange },
        ScrollViewMarks = { fg = colors.palette.dragonGreen },

        Headline1 = { bg = colors.palette.waveBlue1, fg = colors.palette.fujiWhite, bold = true },
        Headline2 = { bg = colors.palette.winterRed, fg = colors.palette.fujiWhite, bold = true },
        Headline3 = { bg = colors.palette.winterYellow, fg = colors.palette.fujiWhite, bold = true },
        Headline4 = { bg = colors.palette.winterGreen, fg = colors.palette.fujiWhite, bold = true },
        Headline5 = { bg = colors.palette.dragonRed, fg = colors.palette.fujiWhite, bold = true },
        Headline6 = { bg = colors.palette.dragonGray, fg = colors.palette.fujiWhite, bold = true },

        IlluminatedWordRead = { bg = colors.palette.dragonBlue, fg = colors.palette.dragonBlack4, bold = true },
        IlluminatedWordText = { bg = colors.palette.dragonBlue, fg = colors.palette.dragonBlack4, bold = true },
        IlluminatedWordWrite = { bg = colors.palette.dragonBlue, fg = colors.palette.dragonBlack4, bold = true },

        SpectreFaint = { fg = colors.palette.fujiGray, italic = false },
      }
    end,
    background = { -- set theme based on background color
      dark = "dragon",
      light = "lotus",
    },
  })
end

return M
