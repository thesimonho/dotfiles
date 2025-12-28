local M = {}

M.border_chars_none = { "", "", "", "", "", "", "", "" }
M.border_chars_empty = { " ", " ", " ", " ", " ", " ", " ", " " }
M.border_chars_inner_thick = { " ", "▄", " ", "▌", " ", "▀", " ", "▐" }
M.border_chars_outer_thick = { "▛", "▀", "▜", "▐", "▟", "▄", "▙", "▌" }
M.border_chars_outer_thin = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
M.border_chars_inner_thin = { " ", "▁", " ", "▏", " ", "▔", " ", "▕" }
M.border_chars_doublethin = { "╒", "═", "╕", "│", "╛", "═", "╘", "│" }
M.border_chars_dot = { "┌", "┄", "┐", "┆", "┘", "┄", "└", "┆" }
M.border_chars_dash = { "╭", "-", "╮", "╎", "╯", "-", "╰", "╎" }

M.progress = { "██", "▇▇", "▆▆", "▅▅", "▄▄", "▃▃", "▂▂", "▁▁", "  " }
M.spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

M.todo_keywords = {
  NOTE = { alt = { "NOTE", "INFO" }, highlight = "DiagnosticHint", icon = "󱞂" },
  FIX = { alt = { "FIX", "FIXME", "BUG", "FIXIT", "ISSUE" }, highlight = "DiagnosticError", icon = "󱙒" },
  HACK = { alt = { "HACK" }, highlight = "DiagnosticWarn", icon = "󱝾" },
  TODO = { alt = { "TODO" }, highlight = "DiagnosticInfo", icon = "󰎛" },
  WARN = { alt = { "WARN", "WARNING", "XXX" }, highlight = "DiagnosticWarn", icon = "󱝾" },
  PERF = { alt = { "PERF", "OPTIM", "PERFORMANCE", "OPTIMIZE" }, highlight = "constant", icon = "" },
  TEST = { alt = { "TEST", "TESTING", "PASSED", "FAILED" }, highlight = "statement", icon = "󰙨" },
}

M.icons = {
  dap = {
    Stopped = { "", "DapStoppedLine" },
    Breakpoint = { "", "DiagnosticError" },
    BreakpointCondition = { "", "DiagnosticHint" },
    BreakpointRejected = { "", "DiagnosticWarn" },
    LogPoint = { "", "DiagnosticInfo" },
  },
  diagnostics = {
    Error = "",
    Warn = "",
    Hint = "",
    Info = "",
  },
  git = {
    added = "",
    modified = "",
    removed = "",
  },
}

return M
