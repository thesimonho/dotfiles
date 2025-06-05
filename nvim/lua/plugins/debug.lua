return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      for _, adapterType in ipairs({ "node", "chrome" }) do
        local pwaType = "pwa-" .. adapterType
        if not dap.adapters[pwaType] then
          dap.adapters[pwaType] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "node",
              args = {
                require("mason-registry").get_package("js-debug-adapter"):get_install_path()
                  .. "/js-debug/src/dapDebugServer.js",
                "${port}",
              },
            },
          }

          -- this allow us to handle launch.json configurations
          -- which specify type as "node" or "chrome" or "msedge"
          dap.adapters[adapterType] = function(cb, config)
            local nativeAdapter = dap.adapters[pwaType]

            config.type = pwaType

            if type(nativeAdapter) == "function" then
              nativeAdapter(cb, config)
            else
              cb(nativeAdapter)
            end
          end
        end
      end

      for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file using Node.js (nvim-dap)",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process using Node.js (nvim-dap)",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            request = "attach",
            name = "Attach to Chrome (pwa-chrome = { port: 9222 })",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            protocol = "inspector",
            port = 9222,
            webRoot = "${workspaceFolder}",
          },
        }
      end
    end,
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
