local M = {}
local namespace = vim.api.nvim_create_namespace("GitReview")
local review = {
  parent = nil,
  created = {},
  buffers = {},
  enabled = false,
  generation = 0,
  pending = {},
}

local function git(cwd, args)
  local cmd = { "git", "-C", cwd }
  vim.list_extend(cmd, args)

  local result = vim.system(cmd, { stdin = "" }):wait()
  if result.code ~= 0 then
    error(("Git %s: %s"):format(table.concat(args, " "), vim.trim(result.stderr or "Git failed")))
  end

  return result.stdout or ""
end

local function refresh_highlights(buf)
  if not review.enabled or not vim.tbl_contains(review.buffers, buf) then
    return
  end
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  local highlights = { add = "GitSignsAddLn", change = "GitSignsChangeLn", delete = "GitSignsDeleteLn" }
  local last_line = vim.api.nvim_buf_line_count(buf)
  for _, hunk in ipairs(require("gitsigns").get_hunks(buf) or {}) do
    local first = math.max(1, hunk.added.start)
    local last = math.min(last_line, first + math.max(1, hunk.added.count) - 1)
    for line = first, last do
      vim.api.nvim_buf_set_extmark(buf, namespace, line - 1, 0, {
        line_hl_group = highlights[hunk.type],
        priority = 90,
      })
    end
  end
end

local function apply_pending_base(buf)
  local generation = review.pending[buf]
  if not review.enabled or generation ~= review.generation or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local gs = require("gitsigns")
  -- A duplicate attach callback can run while BufRead auto-attachment is still pending.
  if gs.get_hunks(buf) == nil then
    return
  end
  review.pending[buf] = nil
  vim.api.nvim_buf_call(buf, function()
    gs.change_base(review.parent, false, function(err)
      if generation ~= review.generation then
        return
      end
      if err then
        vim.notify(tostring(err), vim.log.levels.WARN)
      else
        refresh_highlights(buf)
      end
    end)
  end)
end

local group = vim.api.nvim_create_augroup("GitReviewHighlights", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "GitSignsUpdate",
  callback = function(event)
    local buf = event.data.buffer
    -- Gitsigns may emit its first status update before its buffer cache is ready.
    vim.schedule(function()
      apply_pending_base(buf)
      refresh_highlights(buf)
    end)
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function(event)
    -- Gitsigns can defer updates to loaded buffers until they become visible.
    vim.schedule(function()
      apply_pending_base(event.buf)
    end)
  end,
})

local function set_highlights(enabled)
  local gs = require("gitsigns")
  review.enabled = enabled
  review.generation = review.generation + 1
  local generation = review.generation
  review.pending = {}

  for _, buf in ipairs(review.buffers) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
      if enabled then
        review.pending[buf] = generation
        gs.attach({ bufnr = buf }, function(err)
          if generation ~= review.generation then
            return
          end
          if err then
            vim.notify(tostring(err), vim.log.levels.WARN)
          else
            apply_pending_base(buf)
          end
        end)
      else
        vim.api.nvim_buf_call(buf, gs.reset_base)
      end
    end
  end
end

local function open_commit(commit)
  -- Find the active Lazygit terminal
  local term
  for _, t in ipairs(Snacks.terminal.list()) do
    if type(t.cmd) == "table" and t.cmd[1] == "lazygit" and t:win_valid() then
      term = term or t
      if t.buf == vim.api.nvim_get_current_buf() then
        term = t
        break
      end
    end
  end

  if not term then
    error("No active Snacks Lazygit terminal")
  end

  local terminal = vim.b[term.buf].snacks_terminal or {}
  local cwd = terminal.cwd or vim.api.nvim_win_call(term.win, vim.fn.getcwd)
  local root = vim.trim(git(cwd, { "rev-parse", "--show-toplevel" }))
  local sha = vim.trim(git(root, {
    "rev-parse",
    "--verify",
    commit .. "^{commit}",
  }))
  local parents = vim.split(vim.trim(git(root, { "rev-list", "--parents", "-n", "1", sha })), " ")
  local parent = parents[2] or vim.trim(git(root, { "hash-object", "-t", "tree", "--stdin" }))

  local output = git(root, {
    "diff",
    "--name-only",
    "-z",
    "--find-renames",
    "--diff-filter=ACMRT",
    parent,
    sha,
    "--",
  })

  local buffers = {}
  for _, file in
    ipairs(vim.split(output, "\0", {
      plain = true,
      trimempty = true,
    }))
  do
    local path = root .. "/" .. file
    if vim.fn.filereadable(path) == 1 then
      local existed = vim.fn.bufnr(path) ~= -1
      local buf = vim.fn.bufadd(path)
      vim.fn.bufload(buf)
      vim.bo[buf].buflisted = true

      table.insert(buffers, buf)

      if not existed then
        review.created[buf] = true
      end
    end
  end

  if #buffers == 0 then
    vim.notify("No editable files found in commit")
    return
  end

  if review.enabled then
    set_highlights(false)
  end

  review.parent = parent
  review.buffers = buffers

  -- Hide Lazygit and return to normal editing
  term:hide()
  vim.cmd.stopinsert()
  vim.api.nvim_set_current_buf(buffers[1])
  set_highlights(true)

  vim.notify(("Opened %d files from %s"):format(#buffers, sha:sub(1, 8)))
end

function M.open(commit)
  vim.schedule(function()
    local ok, err = pcall(open_commit, commit)
    if not ok then
      vim.notify(tostring(err), vim.log.levels.ERROR)
    end
  end)
  return 0
end

function M.toggle()
  if not review.parent then
    vim.notify("No commit selected", vim.log.levels.WARN)
    return
  end
  set_highlights(not review.enabled)
end

function M.close()
  if review.enabled then
    set_highlights(false)
  end

  for buf in pairs(review.created) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
      if not ok then
        vim.notify(tostring(err), vim.log.levels.WARN)
      else
        review.created[buf] = nil
      end
    else
      review.created[buf] = nil
    end
  end

  review.buffers = {}
  review.parent = nil
end

return M
