return {
  name = "pytest (all)",
  builder = function()
    return {
      cmd = { "pytest" },
      args = { vim.fn.getcwd() },
      components = { "default" },
    }
  end,
  condition = {
    filetype = { "python" },
  },
}
