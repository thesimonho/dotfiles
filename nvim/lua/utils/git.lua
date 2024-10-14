local builtin = require("telescope.builtin")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

M.is_git_repo = function()
  vim.fn.system("git rev-parse --is-inside-work-tree")
  return vim.v.shell_error == 0
end

M.get_git_root = function()
  local dot_git_path = vim.fn.finddir(".git", ".;")
  return vim.fn.fnamemodify(dot_git_path, ":h")
end

-- when grepping, cd to the project root directory first
M.live_grep_from_project_root = function()
  local opts = {}

  if M.is_git_repo() then
    opts = {
      cwd = M.get_git_root(),
    }
  end

  require("telescope.builtin").live_grep(opts)
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

-- switch to a worktree in a given directory
M.switch_git_worktree = function(dir)
  local worktrees = M.get_git_worktrees(dir)
  if vim.tbl_isempty(worktrees) then
    print("No worktrees found")
    return
  end

  local max_name_length = 0
  for _, entry in ipairs(worktrees) do
    max_name_length = math.max(max_name_length, #entry.name)
  end

  pickers
    .new(
      require("telescope.themes").get_dropdown({
        width = 0.5,
        prompt_title = "Git Worktrees",
        previewer = false,
      }),
      {
        finder = finders.new_table({
          results = worktrees,
          entry_maker = function(entry)
            return {
              value = entry.path, -- Store the full path as the entry value
              display = string.format(
                "%s%s",
                M.pad_string_align(entry.name, max_name_length + 5),
                entry.path -- Path aligned to the right
              ),
              ordinal = entry.name, -- Used for sorting/filtering
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            vim.cmd("tabnew")
            builtin.find_files({ cwd = selection.value })
          end)
          return true
        end,
      }
    )
    :find()
end

return M
