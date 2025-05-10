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
}
