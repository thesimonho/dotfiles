return {
  name = "pytest (file)",
  builder = function()
    return {
      cmd = { "pytest" },
      args = { vim.fn.expand("%:p") },
      components = { "default" },
    }
  end,
  condition = {
    filetype = { "python" },
  },
}
