return {
  name = "Run",
  builder = function()
    local file = vim.fn.expand("%:p")
    return {
      cmd = { "python" },
      args = { file },
      components = { "default" },
    }
  end,
  condition = {
    filetype = { "python" },
  },
}
