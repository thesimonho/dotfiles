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

return M
