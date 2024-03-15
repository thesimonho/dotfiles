return {
  name = "pytest",
  builder = function()
    return {
      cmd = { "pytest" },
      components = { "default" },
    }
  end,
  condition = {
    filetype = { "python" },
  },
}
