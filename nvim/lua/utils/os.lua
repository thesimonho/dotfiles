local M = {}

--- Check if the current OS is macOS
M.is_darwin = function()
  return vim.uv.os_uname().sysname == "Darwin"
end

--- Check if the current OS is Windows
M.is_windows = function()
  return vim.uv.os_uname().sysname == "Windows_NT"
end

--- Check if inside docker container
M.is_container = function()
  if vim.fn.filereadable("/.dockerenv") then
    return true
  end
  return false
end

--- Run callback if this is a remote ssh multiplexer server
--- @param callback function
M.is_wezterm_mux_server = function(callback)
  local wezterm_executable = vim.uv.os_getenv("WEZTERM_EXECUTABLE")
  if wezterm_executable and wezterm_executable:find("wezterm-mux-server", 1, true) then
    callback(true) -- Remote WezTerm session found
  else
    callback(false) -- No remote WezTerm session
  end
end

--- Check if a command is available
--- @param cmd string
M.has_executable = function(cmd)
  return vim.fn.executable(cmd) == 1
end

return M
