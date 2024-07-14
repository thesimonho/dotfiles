return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "LazyFile",
    init = function(_)
      local wk = require("which-key")
      wk.add({
        { "<leader>r", group = "refactor", icon = "" },
        { "<leader>rp", group = "print", icon = "󱞆" },
      })
    end,
    keys = {
      { "<leader>rF", ":Refactor extract ", mode = "v", desc = "Extract to function" },
      { "<leader>rf", ":Refactor inline_func", mode = "n", desc = "Inline function" },
      { "<leader>rV", ":Refactor extract_var ", mode = "v", desc = "Extract to variable" },
      { "<leader>rv", ":Refactor inline_var", mode = { "n", "v" }, desc = "Inline variable" },
      { "<leader>rb", ":Refactor extract_block", mode = "n", desc = "Extract to block" },
      {
        "<leader>rpf",
        function()
          require("refactoring").debug.printf({ below = true, show_success_message = false })
        end,
        mode = "n",
        desc = "function",
      },
      {
        "<leader>rpv",
        function()
          require("refactoring").debug.print_var({ below = true, show_success_message = false })
        end,
        mode = { "n", "v" },
        desc = "variable",
      },
      {
        "<leader>rpc",
        function()
          require("refactoring").debug.cleanup({ show_success_message = false })
        end,
        mode = "n",
        desc = "cleanup",
      },
    },
    opts = {
      prompt_func_return_type = {
        go = true,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      prompt_func_param_type = {
        go = true,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      printf_statements = {},
      print_var_statements = {},
      show_success_message = false,
    },
  },
}
