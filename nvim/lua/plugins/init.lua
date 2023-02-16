-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Install plugin modules
require("lazy").setup("plugins.modules",
  {
    defaults = {
      lazy = false,
      version = nil, -- dont use version="*" ... too risky
    },
    install = {
      missing = true,
    },
    checker = {
      enabled = true,
      notify = true
    },
    change_detection = {
      enabled = true,
      notify = false,
    },
  }
)