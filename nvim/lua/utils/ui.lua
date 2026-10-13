local M = {}

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
