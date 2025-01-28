local Path = require("plenary.path")
local os = require("utils.os")

M = {}

-- find file's root directory based on a list of patterns
Root_cache = {}
M.find_root = function(buf_id, patterns)
  local path = vim.api.nvim_buf_get_name(buf_id)
  if path == "" then
    return
  end
  path = vim.fs.dirname(path)

  -- Try using cache
  local res = Root_cache[path]
  if res ~= nil then
    return res
  end

  -- Find root
  local root_file = vim.fs.find(patterns, { path = path, upward = true })[1]
  if root_file == nil then
    return
  end

  -- Use absolute path and cache result
  res = vim.fn.fnamemodify(vim.fs.dirname(root_file), ":p")
  Root_cache[path] = res

  return res
end

-- Recursive function to find a directory containing the target
M.find_parent_with_directory = function(start_path, target_dir)
  local target_path = vim.fn.fnamemodify(start_path, ":p") .. target_dir
  if vim.loop.fs_stat(target_path) then
    return start_path
  end

  local parent = vim.fn.fnamemodify(start_path, ":h")
  if parent == start_path then
    return nil -- Reached the root directory
  end

  return M.find_parent_with_directory(parent, target_dir)
end

M.get_file_extension = function(fn)
  local match = fn:match("^.+(%..+)$")
  local ext = ""
  if match ~= nil then
    ext = match:sub(2)
  end
  return ext
end

M.get_path_sep = function()
  if os.is_windows() then
    return "\\"
  else
    return "/"
  end
end

-- Shorten a path to a given number of directories
M.shorten_path = function(path, max_parts)
  local components = Path:new(path):_split()
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

M.create_tempfile = function(filename)
  if os.is_windows() then
    return os.getenv("TEMP") .. "/" .. filename
  else
    return "/tmp/" .. filename
  end
end

return M
