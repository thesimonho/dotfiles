local general = require("utils.general")
local fs = require("utils.fs")

local M = {}

-- UI select menu
M.UI_select = function(item_map)
  local options = general.get_table_keys(item_map)
  return vim.ui.select(options, { prompt = "Select option" }, function(item, idx)
    for option, cmd in pairs(item_map) do
      if option == item then
        load(cmd)()
      end
    end
  end)
end

-- Get projects and open fzf picker
M.get_projects = function()
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

-- Display a table in fzf with the current vim options, along with actions to change their values
M.show_options_table = function(separator)
  local sep = separator or "│"

  local format = function(info)
    local fields = { "option", "value" }
    local field_fmt = { option = "%-20s", value = "%s" }
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

  local make_entries = function()
    local raw_options = general.get_vim_options()
    local options = {}

    --PERF: these loops can be combined
    for _, raw in pairs(raw_options) do
      raw.str = format({ option = raw.name, value = tostring(raw.value) })
      local o = string.format("[%s:%s]", raw.name, raw.value)
      options[o] = raw
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

  require("fzf-lua").fzf_exec(function(fzf_cb)
    coroutine.wrap(function()
      local co = coroutine.running()
      local entries = make_entries()
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
            local ok, err = pcall(function()
              vim.cmd(string.format("set %s!", option))
            end)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          elseif info.type == "number" then
            vim.schedule(function()
              vim.ui.input({ prompt = option, default = old, expand = true }, function(updated)
                if not updated or updated == "" or updated == old then
                  return
                end

                local ok, err = pcall(function()
                  vim.cmd(string.format("set %s=%s", option, tonumber(updated)))
                end)
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

                local ok, err = pcall(function()
                  vim.cmd(string.format("set %s=%s", option, updated))
                end)
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

return M
