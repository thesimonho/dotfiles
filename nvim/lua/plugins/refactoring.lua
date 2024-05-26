return {
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>r"] = { name = "  refactor" },
        ["<leader>rp"] = { name = " 󱞆 print" },
      },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "LazyFile",
    keys = {
      { "<leader>rF", ":Refactor extract ", mode = "v", desc = "Extract to function" },
      -- { "<leader>rf", ":Refactor extract_to_file ", mode = "v", desc = "Extract function to file" },
      { "<leader>rf", ":Refactor inline_func", mode = "n", desc = "Inline function" },
      { "<leader>rV", ":Refactor extract_var ", mode = "v", desc = "Extract to variable" },
      { "<leader>rv", ":Refactor inline_var", mode = { "n", "v" }, desc = "Inline variable" },
      { "<leader>rb", ":Refactor extract_block", mode = "n", desc = "Extract to block" },
      -- { "<leader>rbf", ":Refactor extract_block_to_file", mode = "n", desc = "Extract block to file" },
      {
        "<leader>rpf",
        function()
          require("refactoring").debug.printf({ below = true })
        end,
        mode = "n",
        desc = "Print function",
      },
      {
        "<leader>rpv",
        function()
          require("refactoring").debug.print_var({ below = true })
        end,
        mode = { "n", "v" },
        desc = "Print variable",
      },
      {
        "<leader>rpc",
        function()
          require("refactoring").debug.cleanup({})
        end,
        mode = "n",
        desc = "Print cleanup",
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
