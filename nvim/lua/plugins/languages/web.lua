local fs = require("utils.fs")
local wk = require("which-key")

return {
  {
    "williamboman/mason.nvim",
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
}
