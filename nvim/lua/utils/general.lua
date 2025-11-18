local constants = require("config.constants")
local fs = require("utils.fs")

local M = {}

--- Get the number of splits in the current application window
M.get_split_count = function()
  return vim.o.columns / vim.fn.winwidth(0)
end

--- Functional wrapper for mapping custom keybindings
M.map = function(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

--- string padding
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

--- check if string is in table
M.is_string_in_table = function(str, tbl)
  for _, value in pairs(tbl) do
    if value == str then
      return true
    end
  end
  return false
end

--- get all keys from a table
M.get_table_keys = function(tab)
  local keyset = {}
  for k, _ in pairs(tab) do
    keyset[#keyset + 1] = k
  end
  return keyset
end

--- get mini icon or web devicon
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

--- Get buffer progress character
M.get_progress_char = function()
  local current_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")
  local line_ratio = current_line / total_lines
  local index = math.ceil(line_ratio * #constants.progress)
  return constants.progress[index]
end

M.load_help_file = function()
  if M.help then
    return M.help
  end

  local paths = vim.fn.globpath(vim.o.rtp, "doc/options.txt", false, true)
  if #paths == 0 then
    vim.notify("No help file found in runtime path.", vim.log.levels.ERROR)
    return
  end

  M.help = vim.fn.readfile(paths[1])
  return M.help
end

M.get_help_text = function(tag)
  if not M.help then
    M.load_help_file()
  end

  local tag_pattern = "%*'" .. tag .. "'%*"

  local start_index
  for i, line in ipairs(M.help) do
    if line:match(tag_pattern) then
      start_index = i
      break
    end
  end
  if not start_index then
    return nil
  end

  local heading_pattern = "%*'[^']*'%*"
  local end_index = #M.help
  for i = start_index + 1, #M.help do
    if M.help[i]:match(heading_pattern) then
      end_index = i - 1
      break
    end
  end

  local output = {}
  for i = start_index, end_index do
    output[#output + 1] = M.help[i]
  end

  return table.concat(output, "\n")
end

--- copy to system clipboard using OSC52
M.set_osc52_clipboard = function()
  -- paste from clipboard does not work
  -- set to regular nvim paste
  local function paste()
    local content = vim.fn.getreg('"')
    return vim.split(content, "\n")
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
  }
end

--- add current line to quickfix list
M.add_current_line_to_qf = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1]

  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""

  vim.ui.input({ prompt = "Quickfix text (leave empty to use line):" }, function(input)
    if input == nil then
      return
    end

    local text = vim.trim(input)
    if text == "" then
      text = line
    end

    vim.fn.setqflist({
      {
        filename = filename,
        lnum = lnum,
        col = 1,
        text = text,
      },
    }, "a")

    vim.notify("Added line to quickfix", vim.log.levels.INFO)
  end)
end

return M
