-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local fs = require("utils.fs")

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

      if buftype == "terminal" then
        vim.defer_fn(function()
          vim.cmd("startinsert")
        end, 10)
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
    local root = fs.find_root(0, patterns)
    if root == nil then
      return
    end
    vim.cmd("tcd " .. root)
  end,
  desc = "Find root and change current directory",
})

-- spell check
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  command = "setlocal spell",
})

--  cursor
local cursor_group = vim.api.nvim_create_augroup("CursorGroup", { clear = true })

vim.api.nvim_create_autocmd("WinEnter", {
  group = cursor_group,
  callback = function()
    if vim.bo.filetype == "snacks_dashboard" then
      vim.api.nvim_set_option_value("cursorline", false, { win = vim.api.nvim_get_current_win() })
      vim.api.nvim_set_option_value("winblend", 0, { win = vim.api.nvim_get_current_win() })
    elseif vim.bo.filetype == "neo-tree" then
      vim.api.nvim_set_option_value("winblend", 0, { win = vim.api.nvim_get_current_win() })
    else
      vim.api.nvim_set_option_value("cursorline", true, { win = vim.api.nvim_get_current_win() })
      vim.api.nvim_set_option_value("winblend", 6, { win = vim.api.nvim_get_current_win() })
    end
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  group = cursor_group,
  callback = function()
    vim.api.nvim_set_option_value("cursorline", false, { win = vim.api.nvim_get_current_win() })
  end,
})
