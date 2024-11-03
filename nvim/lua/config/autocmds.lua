-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Stop newline comment continuation
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions = vim.opt.formatoptions - { "r", "o", "t", "c" }
  end,
  desc = "Disable comment continuation",
})

-- open help in right split
local help_group = vim.api.nvim_create_augroup("help_window_right", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = help_group,
  pattern = { "*.txt" },
  callback = function()
    if vim.o.filetype == "help" then
      vim.cmd.wincmd("L")
    end
  end,
  desc = "Open help pages in a vertical split",
})

-- insert mode when switching to terminal
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    vim.schedule(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

      if buftype == "terminal" then
        vim.api.nvim_set_option_value("number", false, { scope = "local" })
        vim.api.nvim_set_option_value("relativenumber", false, { scope = "local" })
        vim.api.nvim_command("startinsert")
      elseif filetype ~= "TelescopePrompt" and filetype ~= "alpha" then
        -- without this^, telescope will exit insert when no matches are found
        vim.api.nvim_command("stopinsert")
      end
    end)
  end,
})

-- auto root
local root_group = vim.api.nvim_create_augroup("AutoRoot", {})
vim.api.nvim_create_autocmd("BufEnter", {
  group = root_group,
  callback = function()
    local patterns = { ".git", "package.json", "setup.py" }
    local root = require("utils.general").find_root(0, patterns)
    if root == nil then
      return
    end
    -- vim.fn.chdir(root)
    vim.cmd("tcd " .. root)
  end,
  desc = "Find root and change current directory",
})

-- dashboard
local alpha_group = vim.api.nvim_create_augroup("Dashboard", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = alpha_group,
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    if filetype ~= "alpha" then
      vim.wo.cursorline = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = alpha_group,
  callback = function()
    vim.wo.cursorline = false
  end,
})

-- git statuses
local git_group = vim.api.nvim_create_augroup("GitStatus", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = git_group,
  callback = function()
    local git_dir = vim.fn.trim(vim.fn.system("git rev-parse --git-dir"))
    local git_common_dir = vim.fn.trim(vim.fn.system("git rev-parse --git-common-dir"))

    -- Compare if they are different (indicating a worktree)
    if git_dir ~= git_common_dir then
      vim.g.git_worktree = 1
      vim.g.git_worktree_root = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    else
      vim.g.git_worktree = nil
      vim.g.git_worktree_root = nil
    end
  end,
})

-- spell check
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  command = "setlocal spell",
})
