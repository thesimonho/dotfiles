return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dS",
        function()
          require("osv").launch({ port = 8086 })
        end,
        desc = "Start Nvim Lua Server",
        ft = "lua",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      icons = {
        collapsed = "",
        current_frame = "",
        expanded = "",
      },
      layouts = {
        {
          elements = {
            {
              id = "scopes",
              size = 0.25,
            },
            {
              id = "breakpoints",
              size = 0.25,
            },
            {
              id = "stacks",
              size = 0.25,
            },
            {
              id = "watches",
              size = 0.25,
            },
          },
          position = "left",
          size = 50,
        },
        {
          elements = {
            {
              id = "repl",
              size = 0.5,
            },
            {
              id = "console",
              size = 0.5,
            },
          },
          position = "bottom",
          size = 10,
        },
      },
    },
  },
}
