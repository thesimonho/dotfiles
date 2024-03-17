return {
  {
    "folke/neodev.nvim",
    event = "LazyFile",
    opts = {
      library = {
        plugins = { "neotest" },
        types = true,
      },
    },
  },
  {
    "nvim-neotest/neotest",
    event = "LazyFile",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
    },
    opts = {
      default_strategy = "integrated",
      discovery = {
        enabled = true,
      },
      adapters = {
        require("neotest-go"),
        require("neotest-python")({
          runner = "pytest",
          -- python = "C:\\Users\\simon\\AppData\\Local\\pypoetry\\Cache\\virtualenvs\\herald-of-completion-NCjgh5TX-py3.11\\Scripts",
          -- python = ".venv/bin/python",
        }),
      },
    },
  },
}
