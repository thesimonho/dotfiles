local os_utils = require("utils.os")
local fs = require("utils.fs")
local wk = require("which-key")

local function launch_chrome_debug(port)
  port = port or "9222"
  local args = {
    "--remote-debugging-port=" .. port,
    "--no-first-run",
    "--no-default-browser-check",
    "--user-data-dir=~/.cache/chrome-dap-profile",
    "> /dev/null 2>&1 &",
  }
  local arg_string = table.concat(args, " ")

  local launchers = {
    ["google-chrome"] = {
      check = os_utils.has_executable,
    },
    ["google-chrome-stable"] = {
      check = os_utils.has_executable,
    },
    ["chromium"] = {
      check = os_utils.has_executable,
    },
    ["com.google.Chrome"] = {
      check = os_utils.has_flatpak_app,
      is_flatpak = true,
    },
    ["org.chromium.Chromium"] = {
      check = os_utils.has_flatpak_app,
      is_flatpak = true,
    },
  }

  for cmd, opts in pairs(launchers) do
    if opts.check(cmd) then
      if opts.is_flatpak then
        os.execute("flatpak run " .. cmd .. " " .. arg_string)
      else
        os.execute(cmd .. " " .. arg_string)
      end
      vim.notify("Launched Chrome with remote debugging on port " .. port, vim.log.levels.INFO)
      return true
    end
  end
  vim.notify("Failed to launch Chrome. Please ensure it is installed.", vim.log.levels.ERROR)
  return false
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- linters
        "eslint_d",
        -- formatters
        "prettierd",
        "prettier",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        vue = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
      },
    },
  },
  {
    "vuki656/package-info.nvim",
    enabled = fs.has_in_project("package.json"),
    dependencies = { "MunifTanjim/nui.nvim" },
    ft = { "json" },
    init = function()
      wk.add({ "<localleader>n", group = "  npm" })
    end,
    keys = {
      {
        "<localleader>nh",
        ":lua require('package-info').toggle()<CR>",
        ft = "json",
        desc = "Hide dependencies",
      },
      {
        "<localleader>nd",
        ":lua require('package-info').delete()<CR>",
        ft = "json",
        desc = "Delete dependency",
      },
      {
        "<localleader>nu",
        ":lua require('package-info').update()<CR>",
        ft = "json",
        desc = "Update dependency",
      },
      { "<localleader>nc", ":lua require('package-info').change_version()<CR>", ft = "json", desc = "Change version" },
      {
        "<localleader>ni",
        ":lua require('package-info').install()<CR>",
        ft = "json",
        desc = "Install new dependency",
      },
    },
    opts = {
      colors = {
        up_to_date = "#3C4048", -- Text color for up to date dependency virtual text
        outdated = "#d19a66", -- Text color for outdated dependency virtual text
      },
      autostart = true,
      hide_up_to_date = true,
      hide_unstable_versions = true,
      package_manager = "npm",
    },
  },
  {
    "nvim-neotest/neotest",
    enabled = fs.has_in_project("vite.config.ts"),
    dependencies = {
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
      summary = {
        follow = true,
      },
      output = {
        open_on_run = false,
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    keys = {
      {
        "<localleader>c",
        launch_chrome_debug,
        ft = { "javascriptreact", "typescriptreact", "vue" },
        desc = "Launch Chrome Remote Debugging",
      },
    },
    opts = function()
      local dap = require("dap")
      for _, adapterType in ipairs({ "node", "chrome", "msedge" }) do
        local pwaType = "pwa-" .. adapterType
        if not dap.adapters[pwaType] then
          dap.adapters[pwaType] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "node",
              args = {
                vim.fn.expand("$MASON/packages/js-debug-adapter") .. "/js-debug/src/dapDebugServer.js",
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
}
