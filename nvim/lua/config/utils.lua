local builtin = require("telescope.builtin")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

-- Functional wrapper for mapping custom keybindings
M.map = function(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- when grepping, cd to the project root directory first
M.live_grep_from_project_root = function()
  local function is_git_repo()
    vim.fn.system("git rev-parse --is-inside-work-tree")
    return vim.v.shell_error == 0
  end

  local function get_git_root()
    local dot_git_path = vim.fn.finddir(".git", ".;")
    return vim.fn.fnamemodify(dot_git_path, ":h")
  end

  local opts = {}

  if is_git_repo() then
    opts = {
      cwd = get_git_root(),
    }
  end

  require("telescope.builtin").live_grep(opts)
end

-- get git worktrees for this project
M.get_git_worktrees = function()
  local bare_dir = vim.fn.finddir(".bare", ".;")

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

M.switch_git_worktree = function()
  local worktrees = M.get_git_worktrees()
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

-- check if string is in table
M.is_string_in_table = function(str, tbl)
  for _, value in pairs(tbl) do
    if value == str then
      return true
    end
  end
  return false
end

-- get all keys from a table
M.get_table_keys = function(tab)
  local keyset = {}
  for k, _ in pairs(tab) do
    keyset[#keyset + 1] = k
  end
  return keyset
end

-- UI select menu
M.UI_select = function(item_map)
  local options = M.get_table_keys(item_map)
  return vim.ui.select(options, { prompt = "Select option" }, function(item, idx)
    for option, cmd in pairs(item_map) do
      if option == item then
        load(cmd)()
      end
    end
  end)
end

-- check if cwd is a git repo
M.is_git_repo = function()
  local path = vim.loop.cwd() .. "/.git"
  local ok, _ = vim.loop.fs_stat(path)
  if not ok then
    return false
  else
    return true
  end
end

-- find file's root directory based on a list of patterns
Root_cache = {}
M.find_root = function(buf_id, patterns)
  local path = vim.api.nvim_buf_get_name(buf_id)
  if path == "" then
    return
  end
  path = vim.fs.dirname(path)

  -- Try using cache
  local res = Root_cache[path]
  if res ~= nil then
    return res
  end

  -- Find root
  local root_file = vim.fs.find(patterns, { path = path, upward = true })[1]
  if root_file == nil then
    return
  end

  -- Use absolute path and cache result
  res = vim.fn.fnamemodify(vim.fs.dirname(root_file), ":p")
  Root_cache[path] = res

  return res
end

-- string padding
M.pad_string_align = function(str, spacing)
  return str .. string.rep(" ", spacing - #str)
end

M.pad_string = function(str, len, align)
  local str_len = #str
  if str_len >= len then
    return str
  end

  local pad_len = len - str_len
  local pad = string.rep(" ", pad_len)

  if align == "left" then
    return str .. pad
  elseif align == "right" then
    return pad .. str
  elseif align == "center" then
    local left_pad = math.floor(pad_len / 2)
    local right_pad = pad_len - left_pad
    return string.rep(" ", left_pad) .. str .. string.rep(" ", right_pad)
  end
end

-- create colour gradient from hex values
M.create_gradient = function(start, finish, steps)
  local r1, g1, b1 =
    tonumber("0x" .. start:sub(2, 3)), tonumber("0x" .. start:sub(4, 5)), tonumber("0x" .. start:sub(6, 7))
  local r2, g2, b2 =
    tonumber("0x" .. finish:sub(2, 3)), tonumber("0x" .. finish:sub(4, 5)), tonumber("0x" .. finish:sub(6, 7))

  local r_step = (r2 - r1) / steps
  local g_step = (g2 - g1) / steps
  local b_step = (b2 - b1) / steps

  local gradient = {}
  for i = 1, steps do
    local r = math.floor(r1 + r_step * i)
    local g = math.floor(g1 + g_step * i)
    local b = math.floor(b1 + b_step * i)
    table.insert(gradient, string.format("#%02x%02x%02x", r, g, b))
  end

  return gradient
end

M.get_web_icon = function(fn)
  local nwd = require("nvim-web-devicons")
  local ext = M.get_file_extension(fn)
  return nwd.get_icon(fn, ext, { default = true })
end

M.get_file_extension = function(fn)
  local match = fn:match("^.+(%..+)$")
  local ext = ""
  if match ~= nil then
    ext = match:sub(2)
  end
  return ext
end

M.is_darwin = function()
  return vim.loop.os_uname().sysname == "Darwin"
end

M.is_windows = function()
  return vim.loop.os_uname().sysname == "Windows_NT"
end

M.get_path_sep = function()
  if M.is_windows() then
    return "\\"
  else
    return "/"
  end
end

M.create_tempfile = function(filename)
  if M.is_windows() then
    return os.getenv("TEMP") .. "\\" .. filename
  else
    return "/tmp/" .. filename
  end
end

M.color_num_to_hex = function(num)
  return ("#%06x"):format(num)
end

M.nvim_get_hl_hex = function(ns_id, opts)
  local hl = vim.api.nvim_get_hl(ns_id, opts)
  for _, key in ipairs({ "fg", "bg", "sp" }) do
    hl[key] = hl[key] and M.color_num_to_hex(hl[key])
  end
  return hl
end

M.border_chars_none = { "", "", "", "", "", "", "", "" }
M.border_chars_empty = { " ", " ", " ", " ", " ", " ", " ", " " }
M.border_chars_inner_thick = { " ", "▄", " ", "▌", " ", "▀", " ", "▐" }
M.border_chars_outer_thick = { "▛", "▀", "▜", "▐", "▟", "▄", "▙", "▌" }
M.border_chars_outer_thin = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
M.border_chars_inner_thin = { " ", "▁", " ", "▏", " ", "▔", " ", "▕" }
M.border_chars_outer_thin_telescope = { "▔", "▕", "▁", "▏", "🭽", "🭾", "🭿", "🭼" }
M.border_chars_outer_thick_telescope = { "▀", "▐", "▄", "▌", "▛", "▜", "▟", "▙" }

return M
