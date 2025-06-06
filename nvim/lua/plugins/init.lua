return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
      icons = {
        dap = {
          Stopped = { " ", "DapStoppedLine" },
          Breakpoint = { " ", "DiagnosticError" },
          BreakpointCondition = { " ", "DiagnosticHint" },
          BreakpointRejected = { " ", "DiagnosticWarn" },
          LogPoint = { " ", "DiagnosticInfo" },
        },
        diagnostics = {
          Error = " ",
          Warn = " ",
          Hint = " ",
          Info = " ",
        },
        git = {
          added = " ",
          modified = " ",
          removed = " ",
        },
      },
    },
  },

  -- submodules
  { import = "plugins.colourschemes" },
  { import = "plugins.languages" },
}
