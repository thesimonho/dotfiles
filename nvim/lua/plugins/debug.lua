return {
  {
    "mfussenegger/nvim-dap",
    -- Install the view's session/initialize listeners before a debug session.
    dependencies = { "igorlfs/nvim-dap-view" },
  },
  { "rcarriga/nvim-dap-ui", enabled = false },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>dpt", "<cmd>lua Snacks.profiler.pick()<cr>", desc = "Toggle" },
      {
        "<leader>qp",
        function()
          local flag_file = vim.fn.stdpath("state") .. "/startup_profiler"
          vim.fn.writefile({}, flag_file)
          vim.notify("Profiler will run on next startup")
        end,
        desc = "Profile Next Startup",
      },
    },
  },
  {
    "igorlfs/nvim-dap-view",
    lazy = true,
    keys = {
      { "<leader>dv", "<cmd>lua require('dap-view').toggle()<cr>", desc = "Toggle DAP View" },
      { "<leader>dW", "<cmd>lua require('dap-view').add_expr()<cr>", desc = "Add Watch" },
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<F12>",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
    },
    config = function(_, opts)
      local dv = require("dap-view")
      dv.setup(opts)
      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = { "dap-view", "dap-view-term", "dap-repl" },
        callback = function(evt)
          vim.keymap.set("n", "q", "<C-w>q", { buffer = evt.buf })
        end,
      })
    end,
    opts = {
      auto_toggle = true,
      winbar = {
        default_section = "scopes",
        controls = {
          enabled = true,
          buttons = {
            "play",
            "step_back",
            "step_over",
            "step_into",
            "step_out",
            "run_last",
            "terminate",
            "disconnect",
          },
        },
      },
      windows = {
        terminal = {
          hide = { "go" },
        },
      },
      icons = {
        play = " F5",
        step_back = " F9",
        step_over = " F10",
        step_into = " F11",
        step_out = " F12",
      },
      help = {
        border = "rounded",
      },
    },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    lazy = true,
    opts = {
      all_references = false,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      commented = true,
      virt_text_pos = "eol",
    },
  },
}
