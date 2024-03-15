return {
  name = "go test (all)",
  builder = function()
    return {
      cmd = { "go" },
      args = { "test" },
      cwd = vim.fn.getcwd(),
      components = {
        "default",
      },
    }
  end,
  condition = {
    filetype = { "go" },
  },
}
