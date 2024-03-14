return {
  name = "go test",
  builder = function()
    local current_file = vim.fn.expand("%:p")
    local directory = vim.fn.fnamemodify(current_file, ":h")
    return {
      cmd = { "go" },
      args = { "test", "-v" },
      cwd = directory,
      components = { { "on_complete_notify" }, "default" },
    }
  end,
  condition = {
    filetype = { "go" },
  },
}
