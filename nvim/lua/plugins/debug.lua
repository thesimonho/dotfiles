return {
  { "rcarriga/nvim-dap-ui", enabled = false },
  {
    "igorlfs/nvim-dap-view",
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
    init = function()
      local dap, dv = require("dap"), require("dap-view")
      dap.listeners.before.attach["dap-view-config"] = function()
        dv.open()
      end
      dap.listeners.before.launch["dap-view-config"] = function()
        dv.open()
      end
      dap.listeners.before.event_terminated["dap-view-config"] = function()
        dv.close()
      end
      dap.listeners.before.event_exited["dap-view-config"] = function()
        dv.close()
      end

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
    opts = {
      all_references = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      virt_text_pos = "eol",
    },
  },
}
