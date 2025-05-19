local M = {}

--- Check if the current OS is macOS
M.is_darwin = function()
  return vim.uv.os_uname().sysname == "Darwin"
end

--- Check if the current OS is Windows
M.is_windows = function()
  return vim.uv.os_uname().sysname == "Windows_NT"
end

--- Check if a command is available
--- @param cmd string
M.has_executable = function(cmd)
  return vim.fn.executable(cmd) == 1
end

return M
