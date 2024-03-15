return {
  name = "go run",
  builder = function()
    local current_file = vim.fn.expand("%:p")
    local directory = vim.fn.fnamemodify(current_file, ":h")
    return {
      cmd = { "go" },
      args = { "run", "." },
      cwd = directory,
      components = {
        "default",
        {
          "on_output_parse",
          {
            "on_output_parse",
            parser = {
              stacktrace = {
                -- Skip lines until we hit panic:
                { "test", "^panic:" },
                -- Skip lines until we hit goroutine
                { "skip_until", "^goroutine%s" },
                -- Repeat this parsing sequence
                {
                  "loop",
                  {
                    "sequence",
                    -- First extract the text of the item, but don't append it to the results yet
                    { "extract", { append = false }, { "^(.+)%(.*%)$", "^created by (.+)$" }, "text" },
                    -- Extract the filename and lnum, add to the existing item, then append it to the results
                    { "extract", "^%s+([^:]+.go):([0-9]+)", "filename", "lnum" },
                  },
                },
              },
            },
          },
        },
      },
    }
  end,
  condition = {
    filetype = { "go" },
  },
}
