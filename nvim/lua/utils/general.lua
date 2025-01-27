local style = require("utils.style")
local fs = require("utils.fs")

local M = {}

--- Get the number of splits in the current application window
M.get_split_count = function()
  return vim.o.columns / vim.fn.winwidth(0)
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

-- get mini icon or web devicon
M.get_web_icon = function(filename, library)
  if library == "mini" then
    local mini = require("mini.icons")
    return mini.get("file", filename)
  else
    local ext = fs.get_file_extension(filename)
    local nwd = require("nvim-web-devicons")
    return nwd.get_icon(filename, ext, { default = true })
  end
end

-- Get vim options and their values
M.get_vim_options = function()
  local raw_options = {}
  for _, v in pairs(vim.api.nvim_get_all_options_info()) do
    local ok, value = pcall(vim.api.nvim_get_option_value, v.name, {})

    if ok then
      local color_value = require("fzf-lua").utils.ansi_from_hl("@punctuation", value)
      if value == true then
        color_value = require("fzf-lua").utils.ansi_from_hl("@character", tostring(value))
      elseif value == false then
        color_value = require("fzf-lua").utils.ansi_from_hl("@operator", tostring(value))
      end
      table.insert(raw_options, { name = v.name, value = color_value })
    end
  end
  return raw_options
end

-- Get buffer progress character
M.get_progress_char = function()
  local current_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")
  local line_ratio = current_line / total_lines
  local index = math.ceil(line_ratio * #style.progress)
  return style.progress[index]
end

return M
