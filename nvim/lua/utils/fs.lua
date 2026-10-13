local os = require("utils.os")

local M = {}

M.get_path_sep = function()
  if os.is_windows() then
    return "\\"
  else
    return "/"
  end
end

-- Shorten a path to a given number of directories
M.shorten_path = function(path, max_parts)
  local components = {}
  for part in string.gmatch(path, "[^/]+") do
    table.insert(components, part)
  end

  local count = #components
  if count > max_parts then
    local shortened = {}
    for i = count - max_parts + 1, count do
      table.insert(shortened, components[i])
    end
    return table.concat(shortened, "/")
  end
  return path
end

M.get_path_components = function(path)
  local components = {}
  for part in string.gmatch(path, "[^/]+") do
    table.insert(components, part)
  end
  return components
end

--- check if path has a devcontainer
M.has_container = function(path)
  path = vim.fn.expand(path or vim.fn.getcwd())
  return vim.fn.filereadable(path .. "/.devcontainer.json") == 1
    or vim.fn.filereadable(path .. "/.devcontainer/devcontainer.json") == 1
end

return M
