return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "igorlfs/nvim-dap-view",
      "theHamsta/nvim-dap-virtual-text",
    },
  },
  {
    "igorlfs/nvim-dap-view",
    keys = {
      { "<leader>dv", "<cmd>lua require('dap-view').toggle()<cr>", desc = "Toggle DAP View" },
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
      winbar = {
        controls = {
          enabled = true,
        },
      },
      windows = {
        terminal = {
          hide = { "go" },
        },
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    enabled = false,
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
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      all_references = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      virt_text_pos = "eol",
    },
  },
  {
    "andrewferrier/debugprint.nvim",
    lazy = false, -- Required to make line highlighting work before debugprint is first used
    version = "*", -- Remove if you DON'T want to use the stable version
    init = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "v" },
        { "<leader>dd", group = "debug print" },
      })
    end,
    opts = {
      display_counter = false,
      keymaps = {
        normal = {
          plain_below = "<leader>ddp",
          plain_above = "",
          variable_below = "<leader>ddv",
          variable_above = "",
          variable_below_alwaysprompt = "",
          variable_above_alwaysprompt = "",
          surround_plain = "",
          surround_variable = "<leader>dds",
          surround_variable_alwaysprompt = "",
          textobj_below = "<leader>ddo",
          textobj_above = "",
          textobj_surround = "",
          toggle_comment_debug_prints = "<leader>ddC",
          delete_debug_prints = "<leader>ddD",
        },
        visual = {
          variable_below = "<leader>ddv",
          variable_above = "",
        },
      },
    },
  },
}
