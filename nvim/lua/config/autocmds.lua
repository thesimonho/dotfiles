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

-- Re-enter terminals only while focus still belongs to the event window/buffer.
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(event)
    if vim.bo[event.buf].buftype ~= "terminal" then
      return
    end
    local win = vim.api.nvim_get_current_win()
    vim.schedule(function()
      if
        vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_get_current_win() == win
        and vim.api.nvim_win_get_buf(win) == event.buf
        and vim.bo[event.buf].buftype == "terminal"
      then
        vim.cmd.startinsert()
      end
    end)
  end,
})

-- auto root
local root_group = vim.api.nvim_create_augroup("AutoRoot", {})
vim.api.nvim_create_autocmd("BufEnter", {
  group = root_group,
  callback = function()
    local root = Snacks.git.get_root()
    if root == nil then
      return
    end
    if vim.fn.getcwd(-1, 0) ~= root then
      vim.cmd.tcd(vim.fn.fnameescape(root))
    end
  end,
  desc = "Find root and change current directory",
})

-- spell check
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text" },
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

-- Set special-buffer defaults once; leave later manual toggles intact.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "toggleterm", "checkhealth", "snacks_notif_history", "bigfile", "qf", "help" },
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
  desc = "Hide line numbers in utility buffers",
})

-- In quickfix window, press `dd` to remove the current entry
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "dd", function()
      local win = vim.api.nvim_get_current_win()
      local is_loclist = vim.fn.getwininfo(win)[1].loclist == 1
      local list = is_loclist and vim.fn.getloclist(win, { items = 0, id = 0 })
        or vim.fn.getqflist({ items = 0, id = 0 })
      local idx = vim.fn.line(".")
      if idx > #list.items then
        return
      end
      table.remove(list.items, idx)
      local what = { id = list.id, items = list.items, idx = math.min(idx, #list.items) }
      if is_loclist then
        vim.fn.setloclist(win, {}, "r", what)
      else
        vim.fn.setqflist({}, "r", what)
      end
    end, { buffer = true, desc = "Delete quickfix entry" })
  end,
})

-- File arguments load this config before Snacks; resolve debug helpers on use.
_G.dd = function(...)
  return require("snacks").debug.inspect(...)
end
_G.bt = function(...)
  return require("snacks").debug.backtrace(...)
end
vim.print = _G.dd
