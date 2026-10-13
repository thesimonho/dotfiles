local M = {}

-- Optional routing for new project terminals. A devcontainer definition does
-- not create a DevPod workspace; its SSH alias must already be configured.
function M.terminal_command(term_num)
  if vim.g.devpod_terminals ~= true then
    return
  end

  local fs = require("utils.fs")
  if not fs.has_container() or require("utils.os").is_container() then
    return
  end

  local path = fs.get_path_components(vim.fn.getcwd())
  local container_name = path[#path]:lower():gsub("[ _]", "-")
  local cmd = "ssh " .. container_name .. ".devpod"
  vim.notify_once("Connecting to DevPod: " .. container_name, vim.log.levels.INFO)
  return term_num .. "TermExec cmd='" .. cmd .. "' go_back=0 direction='float'"
end

return M
