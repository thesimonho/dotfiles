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
        { "<leader>dd", group = "Debug Print" },
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
