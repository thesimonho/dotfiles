local os_utils = require("utils.os")
if not os_utils.has_executable("go") then
  return {}
end

return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = {
      -- dap-go owns the adapter and built-in launch/attach configurations.
      handlers = { delve = function() end },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
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
  {
    "folke/snacks.nvim",
    keys = {
      {
        "gh",
        function()
          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2] + 1
          for first, last in line:gmatch('()"[^"]+"()') do
            if col >= first and col < last then
              vim.ui.open("https://pkg.go.dev/" .. line:sub(first + 1, last - 2))
              return
            end
          end
          vim.notify("Put cursor inside an import path string", vim.log.levels.INFO)
        end,
        ft = { "go", "gomod" },
        desc = "Open Go docs for import",
      },
    },
  },
  {
    "leoluz/nvim-dap-go",
    optional = true,
    lazy = true,
    config = function(_, opts)
      require("dap-go").setup(opts)
      local dap = require("dap")
      -- Resolve project and file paths when launching, after project switches.
      for _, config in ipairs(dap.configurations.go or {}) do
        if config.request == "launch" then
          config.cwd = function()
            return vim.fn.resolve(vim.fn.getcwd())
          end
          if config.program == "${file}" then
            config.program = function()
              return vim.fn.resolve(vim.fn.expand("%:p"))
            end
          elseif config.program == "${fileDirname}" then
            config.program = function()
              return vim.fn.resolve(vim.fn.expand("%:p:h"))
            end
          end
        end
      end
      local adapter = dap.adapters.go
      dap.adapters.go = function(callback, config)
        adapter(function(resolved)
          resolved = vim.deepcopy(resolved)
          resolved.executable.cwd = vim.fn.resolve(config.cwd or vim.fn.getcwd())
          callback(resolved)
        end, config)
      end
    end,
  },
}
