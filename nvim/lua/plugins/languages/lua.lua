return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua",
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
