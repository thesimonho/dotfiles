local M = {}

M.is_darwin = function()
  return vim.loop.os_uname().sysname == "Darwin"
end

M.is_windows = function()
  return vim.loop.os_uname().sysname == "Windows_NT"
end

-- Functional wrapper for mapping custom keybindings
M.map = function(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- string padding
M.pad_string_align = function(str, spacing)
  return str .. string.rep(" ", spacing - #str)
end

M.pad_string = function(str, len, align)
  local str_len = #str
  if str_len >= len then
    return str
  end

  local pad_len = len - str_len
  local pad = string.rep(" ", pad_len)

  if align == "left" then
    return str .. pad
  elseif align == "right" then
    return pad .. str
  elseif align == "center" then
    local left_pad = math.floor(pad_len / 2)
    local right_pad = pad_len - left_pad
    return string.rep(" ", left_pad) .. str .. string.rep(" ", right_pad)
  end
end

-- check if string is in table
M.is_string_in_table = function(str, tbl)
  for _, value in pairs(tbl) do
    if value == str then
      return true
    end
  end
  return false
end

-- get all keys from a table
M.get_table_keys = function(tab)
  local keyset = {}
  for k, _ in pairs(tab) do
    keyset[#keyset + 1] = k
  end
  return keyset
end

-- UI select menu
M.UI_select = function(item_map)
  local options = M.get_table_keys(item_map)
  return vim.ui.select(options, { prompt = "Select option" }, function(item, idx)
    for option, cmd in pairs(item_map) do
      if option == item then
        load(cmd)()
      end
    end
  end)
end

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

M.get_file_extension = function(fn)
  local match = fn:match("^.+(%..+)$")
  local ext = ""
  if match ~= nil then
    ext = match:sub(2)
  end
  return ext
end

M.get_path_sep = function()
  if M.is_windows() then
    return "\\"
  else
    return "/"
  end
end

M.create_tempfile = function(filename)
  if M.is_windows() then
    return os.getenv("TEMP") .. "\\" .. filename
  else
    return "/tmp/" .. filename
  end
end

M.get_web_icon = function(filename, library)
  if library == "mini" then
    local mini = require("mini.icons")
    return mini.get("file", filename)
  else
    local ext = M.get_file_extension(filename)
    local nwd = require("nvim-web-devicons")
    return nwd.get_icon(filename, ext, { default = true })
  end
end

return M
