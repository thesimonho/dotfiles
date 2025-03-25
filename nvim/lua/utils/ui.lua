local general = require("utils.general")

local M = {}

-- UI select menu
M.ui_select = function(item_map)
  local options = general.get_table_keys(item_map)
  return vim.ui.select(options, { prompt = "Select option" }, function(item)
    for option, cmd in pairs(item_map) do
      if option == item then
        load(cmd)()
      end
    end
  end)
end

M.load_project_session = function(dir)
  vim.fn.chdir(dir)
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
      Snacks.picker.files({ dirs = { dir } })
    end
  end, 100)
  vim.cmd("lua require('persistence').load()")
end

return M
