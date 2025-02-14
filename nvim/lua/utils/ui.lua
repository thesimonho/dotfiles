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
    preview = "ls -vA --group-directories-first --color=always {1}",
    actions = {
      ["default"] = function(selected)
        local path = vim.split(selected[1], "!!")[1]

        -- try to load a session
        vim.cmd("tabnew")
        vim.fn.chdir(path)
        local session_loaded = false
        vim.api.nvim_create_autocmd("SessionLoadPost", {
          once = true,
          callback = function()
            session_loaded = true
          end,
        })

        -- fallback to picker
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
    winopts = {
      height = 0.45,
      width = 0.40,
      row = 0.50,
      col = 0.50,
      title = " Projects ",
      title_pos = "center",
      preview = {
        default = "bat",
        wrap = false,
        layout = "horizontal",
      },
    },
  })
end

return M
