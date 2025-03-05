local flag_file = vim.fn.stdpath("state") .. "/startup_profiler"
if vim.fn.filereadable(flag_file) == 1 then
  vim.fn.delete(flag_file) -- Remove flag so it doesn’t persist
  vim.env.PROF = "1"
end

if vim.env.PROF then
  local snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
  vim.opt.rtp:append(snacks)
  require("snacks.profiler").startup({
    startup = {
      event = "VeryLazy",
    },
  })
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
