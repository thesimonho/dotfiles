local M = {}

M.load_project_session = function(dir)
  vim.fn.chdir(dir)

  local persisted = require("persisted")
  local session = persisted.current()
  local has_session = session and vim.fn.filereadable(session) ~= 0

  if has_session then
    -- Persisted.load schedules `silent! source`, so an outer pcall cannot
    -- report restore errors. Keep its lifecycle here, with strict sourcing.
    local config = require("persisted.config")
    vim.g.persisting_session = not config.follow_cwd and session or nil
    vim.g.persisted_loaded_session = session
    local ok, err = pcall(function()
      persisted.fire("LoadPre")
      vim.cmd.source(vim.fn.fnameescape(session))
      persisted.fire("LoadPost")
    end)
    if not ok then
      vim.g.SessionLoad = nil
      vim.g.persisted_loaded_session = nil
      vim.g.project_session_load_failed = true
      persisted.stop()
      vim.notify(
        "Could not restore session " .. session .. ":\n" .. tostring(err) .. "\nAutomatic session saving is stopped.",
        vim.log.levels.ERROR,
        { title = "Project session" }
      )
      return
    end
    vim.g.project_session_load_failed = nil
  else
    vim.g.project_session_load_failed = nil
    Snacks.picker.files({ root = false, hidden = true, dirs = { dir } })
  end
  if require("persisted.config").autostart and persisted.allowed_dir() then
    persisted.start()
  end
end

return M
