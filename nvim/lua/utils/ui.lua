local general = require("utils.general")
local fs = require("utils.fs")

local M = {}

-- UI select menu
M.UI_select = function(item_map)
  local options = general.get_table_keys(item_map)
  return vim.ui.select(options, { prompt = "Select option" }, function(item)
    for option, cmd in pairs(item_map) do
      if option == item then
        load(cmd)()
      end
    end
  end)
end

-- Get projects and open fzf picker
M.show_projects_table = function()
  local projects = Snacks.dashboard.sections.projects({ limit = 50 })
  require("fzf-lua").fzf_exec(function(fzf_cb)
    for _, project in ipairs(projects) do
      local parts = vim.split(project.file, fs.get_path_sep())
      fzf_cb(project.file .. "!!" .. parts[#parts])
    end
    fzf_cb()
  end, {
    prompt = "Projects > ",
    preview = "ls -vA --group-directories-first --color=always {1}",
    actions = {
      ["default"] = function(selected)
        local path = vim.split(selected[1], "!!")[1]

        -- try to load a session, fallback to picker
        vim.cmd("tabnew")
        vim.fn.chdir(path)
        local session_loaded = false
        vim.api.nvim_create_autocmd("SessionLoadPost", {
          once = true,
          callback = function()
            session_loaded = true
          end,
        })

        vim.defer_fn(function()
          if not session_loaded then
            vim.cmd("FzfLua files cwd=" .. path)
          end
        end, 100)
        vim.cmd("lua require('persistence').load()")
      end,
    },
    fzf_opts = {
      ["--delimiter"] = "!!",
      ["--with-nth"] = "2..",
    },
  })
end

-- Format vim options and their values for fzf
M.format_option_entries = function(separator)
  local format = function(info)
    local fields = { "option", "value" }
    local field_fmt = { option = "%-20s", value = "%s" }
    local ret

    for _, f in ipairs(fields) do
      if field_fmt[f] then
        ret = string.format(
          "%s%s" .. field_fmt[f],
          ret or "",
          ret and string.format(" %s ", require("fzf-lua").utils.ansi_from_hl("@punctuation", separator)) or "",
          info[f] or ""
        )
      end
    end
    return ret
  end

  local entries = {}
  for _, v in pairs(vim.api.nvim_get_all_options_info()) do
    local ok, value = pcall(vim.api.nvim_get_option_value, v.name, {})

    if ok then
      local color_value = require("fzf-lua").utils.ansi_from_hl("@punctuation", value)
      if value == true then
        color_value = require("fzf-lua").utils.ansi_from_hl("@character", tostring(value))
      elseif value == false then
        color_value = require("fzf-lua").utils.ansi_from_hl("@operator", tostring(value))
      end

      local str = format({ option = v.name, value = tostring(color_value) })
      table.insert(entries, str)
    end
  end

  table.sort(entries)
  local header = format({ option = "Option", value = "Value" })
  table.insert(entries, 1, header)
  return entries
end

-- show input for new option value
M.show_option_value_input = function(option, old, transform)
  vim.ui.input({ prompt = option, default = old, expand = true }, function(updated)
    if not updated or updated == "" or updated == old then
      return
    end

    local transformed_value = transform and transform(updated) or updated

    local ok, err = pcall(function()
      vim.cmd(string.format("set %s=%s", option, transformed_value))
    end)
    if not ok and err then
      local relevant_error = err:match("Vim%([^%)]+%):%s*(.-)$") or err
      vim.notify(relevant_error, vim.log.levels.ERROR)
    end
    require("fzf-lua").actions.resume()
  end)
end

-- Display an fzf table with the current vim options, along with actions to change their values
M.show_options_table = function(separator)
  local sep = separator or "│"

  require("fzf-lua").fzf_exec(function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local entries = M.format_option_entries(sep)
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
    prompt = "Options > ",
    preview = "echo {2}",
    actions = {
      ["default"] = {
        function(selected)
          local parts = vim.split(selected[1], sep)
          local option = vim.trim(parts[1])
          local old = vim.trim(parts[2])
          local info = vim.api.nvim_get_option_info2(option, {})

          if info.type == "boolean" then
            local ok, err = pcall(function()
              vim.cmd(string.format("set %s!", option))
            end)
            if not ok and err then
              local relevant_error = err:match("Vim%([^%)]+%):%s*(.-)$") or err
              vim.notify(relevant_error, vim.log.levels.ERROR)
            end
          elseif info.type == "number" then
            vim.schedule(function()
              M.show_option_value_input(option, old, tonumber)
            end)
          else
            vim.schedule(function()
              M.show_option_value_input(option, old, nil)
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

return M
