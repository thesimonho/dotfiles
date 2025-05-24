local os = require("utils.os")

local M = {}

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
  if vim.uv.fs_stat(target_path) then
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

M.create_tempfile = function(filename)
  if os.is_windows() then
    return os.getenv("TEMP") .. "/" .. filename
  else
    return "/tmp/" .. filename
  end
end

--- check if path has a devcontainer
M.has_container = function(path)
  path = vim.fn.expand(path or vim.fn.getcwd())
  local devcontainer_path = path .. "/.devcontainer.json"
  if vim.fn.filereadable(devcontainer_path) == 1 then
    return true
  end

  return false
end

M.in_container = function()
  local docker_env = "/.dockerenv"
  if vim.fn.filereadable(docker_env) == 1 then
    return true
  end
  return false
end

--- Check if a file exists in a directory or subdirectories
--- @param filename string filename to search for
--- @param directory string | nil (default "~/Projects") directory to search in
--- @param depth number | nil (default 1) max levels to search down. 0 means only search in the provided directory and not subdirectories
M.has_in_project = function(filename, directory, depth)
  local ignore = {
    ["node_modules"] = true,
    ["__pycache__"] = true,
    ["logs"] = true,
    ["cache"] = true,
    ["config"] = true,
    ["assets"] = true,
    ["images"] = true,
    ["docs"] = true,
    ["examples"] = true,
    ["lost+found"] = true,
  }

  directory = vim.fn.expand(directory or "~/Projects")
  depth = depth or 1 -- Default to searching one level deep

  if vim.fn.isdirectory(directory) == 0 then
    return false
  end

  local function is_ignored(name)
    return name:sub(1, 1) == "." or ignore[name]
  end

  local function search_dir(dir, remaining_depth)
    if remaining_depth < 0 then
      return false
    end

    local entries = vim.fn.readdir(dir)
    for _, name in ipairs(entries) do
      if not is_ignored(name) then
        local path = dir .. "/" .. name
        if vim.fn.isdirectory(path) == 1 then
          -- Check for target file
          if vim.fn.filereadable(path .. "/" .. filename) == 1 then
            return true
          end
          -- Recurse into subdirectory
          if remaining_depth > 0 and search_dir(path, remaining_depth - 1) then
            return true
          end
        end
      end
    end

    return false
  end

  return search_dir(directory, depth)
end

return M
