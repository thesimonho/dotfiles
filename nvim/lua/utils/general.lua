local style = require("utils.style")

local M = {}

M.is_darwin = function()
  return vim.loop.os_uname().sysname == "Darwin"
end

M.is_windows = function()
  return vim.loop.os_uname().sysname == "Windows_NT"
end

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

-- Get projects and open fzf picker
M.get_projects = function()
  local projects = Snacks.dashboard.sections.projects({ limit = 50 })
  require("fzf-lua").fzf_exec(function(fzf_cb)
    for _, project in ipairs(projects) do
      local parts = vim.split(project.file, M.get_path_sep())
      fzf_cb(project.file .. "!!" .. parts[#parts])
    end
    fzf_cb()
  end, {
    prompt = "Projects > ",
    preview = "ls -vA --group-directories-first --color=always {1}",
    actions = {
      ["default"] = function(selected)
        local path = vim.split(selected[1], "!!")[1]
        vim.cmd("tabnew")
        vim.cmd("FzfLua files cwd=" .. path)
      end,
    },
    fzf_opts = {
      ["--delimiter"] = "!!",
      ["--with-nth"] = "2..",
    },
  })
end

-- Get vim options and their values
M.get_vim_options = function(sep)
  local fields = { "option", "value" }
  local field_fmt = { option = "%-20s", value = "%s" }
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

  local options = {}

  local format = function(info)
    local ret
    for _, f in ipairs(fields) do
      if field_fmt[f] then
        ret = string.format(
          "%s%s" .. field_fmt[f],
          ret or "",
          ret and string.format(" %s ", require("fzf-lua").utils.ansi_from_hl("@punctuation", sep)) or "",
          info[f] or ""
        )
      end
    end
    return ret
  end

  local make_entry = function(raw)
    raw.str = format({ option = raw.name, value = tostring(raw.value) })
    local o = string.format("[%s:%s]", raw.name, raw.value)
    options[o] = raw
  end

  --PERF: these loops can be combined
  for _, raw in pairs(raw_options) do
    make_entry(raw)
  end

  local entries = {}
  for _, option in pairs(options) do
    table.insert(entries, option.str)
  end
  table.sort(entries)
  local header_str = format({ option = "option", value = "value" })
  table.insert(entries, 1, header_str)

  return entries
end

-- Display a table in fzf with the current vim options, along with actions to change their values
M.show_options_table = function(separator)
  local sep = separator or "│"

  require("fzf-lua").fzf_exec(function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local entries = M.get_vim_options(sep)
      for _, entry in pairs(entries) do
        vim.schedule(function()
          fzf_cb(entry, function()
            coroutine.resume(co)
          end)
        end)
        coroutine.yield()
      end
      fzf_cb()
    end)()
  end, {
    prompt = "Vim Options > ",
    preview = "echo {2}",
    actions = {
      ["default"] = {
        function(selected)
          local parts = vim.split(selected[1], sep)
          local option = vim.trim(parts[1])
          local old = vim.trim(parts[2])
          local info = vim.api.nvim_get_option_info2(option, {})

          if info.type == "boolean" then
            local ok, err = pcall(vim.cmd, string.format("set %s!", option))
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          elseif info.type == "number" then
            vim.schedule(function()
              vim.ui.input({ prompt = option, default = old, expand = true }, function(updated)
                if not updated or updated == "" or updated == old then
                  return
                end

                local ok, err = pcall(vim.cmd, string.format("set %s=%s", option, tonumber(updated)))
                if not ok then
                  vim.notify(err, vim.log.levels.ERROR)
                end
                require("fzf-lua").actions.resume()
              end)
            end)
          else
            vim.schedule(function()
              vim.ui.input({ prompt = option, default = old, expand = true }, function(updated)
                if not updated or updated == "" or updated == old then
                  return
                end

                local ok, err = pcall(vim.cmd, string.format("set %s=%s", option, updated))
                if not ok then
                  vim.notify(err, vim.log.levels.ERROR)
                end
                require("fzf-lua").actions.resume()
              end)
            end)
          end
        end,
        require("fzf-lua").actions.resume,
      },
    },
    fzf_opts = {
      ["--header-lines"] = "1",
      ["--nth"] = 1,
      ["--delimiter"] = sep,
    },
  })
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
