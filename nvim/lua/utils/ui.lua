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

  local persisted = require("persisted")
  local session = persisted.current()
  local has_session = session and vim.fn.filereadable(session) ~= 0

  if has_session then
    pcall(persisted.load)
  else
    Snacks.picker.files({ root = false, hidden = true, dirs = { dir } })
  end
end

return M
