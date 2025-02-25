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

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermLeave" }, {
  group = cursor_group,
  callback = function()
    local ignore_ft = { "snacks_dashboard" }
    local win = vim.api.nvim_get_current_win()

    if vim.tbl_contains(ignore_ft, vim.bo.filetype) then
      vim.api.nvim_set_option_value("cursorline", false, { win = win })
    else
      vim.api.nvim_set_option_value("cursorline", true, { win = win })
    end
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  group = cursor_group,
  callback = function()
    vim.api.nvim_set_option_value("cursorline", false, { win = vim.api.nvim_get_current_win() })
  end,
})

-- winblend
local winblend_group = vim.api.nvim_create_augroup("WinblendGroup", { clear = true })

vim.api.nvim_create_autocmd("WinEnter", {
  group = winblend_group,
  callback = function()
    local ignore_ft = { "snacks_dashboard", "neo-tree" }
    local win = vim.api.nvim_get_current_win()

    if vim.tbl_contains(ignore_ft, vim.bo.filetype) then
      vim.api.nvim_set_option_value("winblend", 0, { win = win })
    else
      vim.api.nvim_set_option_value("winblend", 3, { win = win })
    end
  end,
})

vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = winblend_group,
  pattern = { "/", "?" },
  callback = function()
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_option_value("winblend", 0, { win = win })
  end,
})

-- line numbers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local ignore_ft = { "toggleterm", "checkhealth", "snacks_notif_history" }
    local ignore_buftype = { "quickfix", "nofile", "prompt", "terminal", "help" }
    local win = vim.api.nvim_get_current_win()

    if vim.tbl_contains(ignore_ft, vim.bo.filetype) or vim.tbl_contains(ignore_buftype, vim.bo.buftype) then
      vim.api.nvim_set_option_value("number", false, { win = win })
      vim.api.nvim_set_option_value("relativenumber", false, { win = win })
    else
      vim.api.nvim_set_option_value("number", true, { win = win })
      vim.api.nvim_set_option_value("relativenumber", true, { win = win })
    end
  end,
  desc = "Toggle line numbers",
})

-- clear args before saving a session
vim.api.nvim_create_autocmd({ "VimLeavePre", "TabLeave", "TabClosed" }, {
  callback = function()
    local arglist = vim.fn.argv()
    if #arglist > 0 then
      vim.cmd("argdelete *")
    end
  end,
})
