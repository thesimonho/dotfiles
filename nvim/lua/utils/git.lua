local M = {}

M.is_git_repo = function()
  vim.fn.system("git rev-parse --is-inside-work-tree")
  return vim.v.shell_error == 0
end

M.get_git_root = function()
  local dot_git_path = vim.fn.finddir(".git", ".;")
  return vim.fn.fnamemodify(dot_git_path, ":h")
end

-- get git worktrees for a project directory
M.get_git_worktrees = function(dir)
  if dir == nil then
    dir = "."
  end

  local bare_dir = vim.fn.finddir(".bare", dir .. ";")

  if bare_dir == nil or bare_dir == "" then
    return {} -- Return empty if no `.bare` directory is found
  end

  local worktrees_dir = vim.fn.fnamemodify(bare_dir, ":h")
  local worktrees = {}

  local siblings = vim.fn.globpath(worktrees_dir, "*", 0, 1)
  for _, path in ipairs(siblings) do
    if vim.fn.isdirectory(path) == 1 and vim.fn.fnamemodify(path, ":t") ~= ".bare" then
      table.insert(worktrees, {
        path = path,
        name = vim.fn.fnamemodify(path, ":t"),
      })
    end
  end

  return worktrees
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
