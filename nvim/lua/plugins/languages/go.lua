local os_utils = require("utils.os")
if not os_utils.has_executable("go") then
  return {}
end

return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "golangci-lint",
        "golines",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "golines", "gofumpt" },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        go = { "golangcilint" }, -- BUG: linter doesnt run, and takes LSP out when it tries
      },
    },
  },
  {
    "leoluz/nvim-dap-go",
    optional = true,
    opts = function(_, opts)
      local resolve_cwd = vim.fn.resolve(vim.fn.getcwd())

      opts.delve = vim.tbl_deep_extend("force", opts.delve or {}, {
        path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
        port = "${port}",
        args = {},
        build_flags = {},
        cwd = resolve_cwd,
      })

      -- DAP configurations (custom test config + patching)
      opts.dap_configurations = opts.dap_configurations or {}
      table.insert(opts.dap_configurations, {})

      -- Filter out any config that doesn't start with "Delve"
      vim.schedule(function()
        local dap = require("dap")
        local configs = dap.configurations.go or {}
        -- this removes the generic vscode configs
        dap.configurations.go = vim.tbl_filter(function(cfg)
          return cfg.name and cfg.name:match("^Delve")
        end, configs)
      end)

      -- patch configs with the correct paths to account for symlinked directories
      for _, cfg in ipairs(opts.dap_configurations) do
        if cfg.type == "go" then
          cfg.cwd = vim.fn.resolve(cfg.cwd or vim.fn.getcwd())

          if cfg.program == "${file}" or not cfg.program then
            -- Resolve to absolute real path
            cfg.program = vim.fn.resolve(vim.fn.expand("%:p"))
          end
        end
      end
    end,
  },
}
