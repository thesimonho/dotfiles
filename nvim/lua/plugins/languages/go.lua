local os_utils = require("utils.os")
if not os_utils.has_executable("go") then
  return {}
end

return {
  {
    "mason-org/mason.nvim",
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
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "go",
      },
    },
  },
  {
    "folke/snacks.nvim",
    ft = { "go", "gomod" },
    config = function(_, opts)
      require("snacks").setup(opts)

      local function open_pkg_go_dev_under_cursor()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1

        for s, e in line:gmatch('()"[^"]+"()') do
          if col >= s and col <= e then
            local path = line:sub(s + 1, e - 2)
            vim.ui.open(("https://pkg.go.dev/%s"):format(path))
            return
          end
        end

        vim.notify("Put cursor inside an import path string", vim.log.levels.INFO)
      end

      local Snacks = require("snacks")
      Snacks.keymap.set("n", "gh", open_pkg_go_dev_under_cursor, {
        desc = "Open Go docs for import",
        ft = { "go", "gomod" },
      })
    end,
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
