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
      local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
      local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

      if buftype == "terminal" then
        vim.api.nvim_win_set_option(0, "number", false)
        vim.api.nvim_win_set_option(0, "relativenumber", false)
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
    local root = require("config/utils").find_root(0, patterns)
    if root == nil then
      return
    end
    -- vim.fn.chdir(root)
    vim.cmd("tcd " .. root)
  end,
  desc = "Find root and change current directory",
})

-- NC line numbers
local nc_group = vim.api.nvim_create_augroup("ToggleLineNC", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = nc_group,
  callback = function()
    vim.wo.cursorline = true
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = nc_group,
  callback = function()
    vim.wo.cursorline = false
  end,
})
