return {
  name = "go test",
  builder = function()
    local current_file = vim.fn.expand("%:p")
    local directory = vim.fn.fnamemodify(current_file, ":h")
    return {
      cmd = { "go" },
      args = { "test" },
      cwd = directory,
      components = {
        "default",
      },
    }
  end,
  condition = {
    filetype = { "go" },
  },
}
