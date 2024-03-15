return {
  name = "go build",
  builder = function()
    return {
      cmd = { "go" },
      args = { "build", "-o", "build/" },
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
