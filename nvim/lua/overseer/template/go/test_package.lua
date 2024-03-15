return {
  name = "go test (package)",
  builder = function()
    return {
      cmd = { "go" },
      args = { "test" },
      cwd = vim.fn.expand("%:p:h"),
      components = {
        "default",
      },
    }
  end,
  condition = {
    filetype = { "go" },
  },
}
