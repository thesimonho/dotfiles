local M = {}

--- Run Git in an explicit directory; return raw stdout or raise on failure.
--- @param cwd string
--- @param args string[]
--- @return string
M.run = function(cwd, args)
  local cmd = { "git", "-C", cwd }
  vim.list_extend(cmd, args)

  local result = vim.system(cmd, { stdin = "" }):wait()
  if result.code ~= 0 then
    error(("Git %s: %s"):format(table.concat(args, " "), vim.trim(result.stderr or "Git failed")))
  end

  return result.stdout or ""
end

--- Resolve a working-tree root, including worktrees with a .git file.
--- @param cwd string|nil Defaults to the current editor directory.
--- @return string|nil Root directory, or nil when Git cannot resolve it.
M.get_git_root = function(cwd)
  local ok, output = pcall(M.run, cwd or vim.fn.getcwd(), { "rev-parse", "--show-toplevel" })
  if not ok then
    return nil
  end
  return vim.trim(output)
end

-- Use the 'gitsigns' extmark to check the Git status HL at a line
M.get_git_sign_hl = function(buf, lnum)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1,
    { lnum - 1, 0 },
    { lnum - 1, -1 },
    { details = true, type = "sign" }
  )

  for _, extmark in pairs(extmarks) do
    local name = extmark[4].sign_hl_group or extmark[4].sign_name or ""
    if name then
      if name:find("GitSignsAdd") then
        return "GitSignsAddNr"
      elseif name:find("GitSignsChange") then
        return "GitSignsChangeNr"
      elseif name:find("GitSignsDelete") then
        return "GitSignsDeleteNr"
      end
    end
  end
  return nil
end

return M
