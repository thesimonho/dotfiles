return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
      icons = {
        dap = {
          Stopped = { " ", "DapUIPlayPause", "DapStoppedLine" },
          Breakpoint = { " ", "DapUIBreakpointsCurrentLine" },
          BreakpointCondition = { " ", "DapUIBreakpointsWarn" },
          BreakpointRejected = { " ", "DapUIBreakpointsWarn" },
          LogPoint = { " ", "DapUIBreakpointsInfo" },
        },
        diagnostics = {
          Error = " ",
          Warn = " ",
          Hint = " ",
          Info = " ",
        },
        git = {
          added = "  ",
          modified = "  ",
          removed = "  ",
        },
      },
    },
  },

  -- submodules
  { import = "plugins.colourschemes" },
  { import = "plugins.languages" },

  -- disabled
  { "akinsho/bufferline.nvim", enabled = false },
  { "echasnovski/mini.pairs", enabled = false },
}
