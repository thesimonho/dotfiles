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
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
}
