local M = {
  "nvim-lualine/lualine.nvim",
  enabled = true,
  opts = function()
    local colours = require("../config/colours")
    local custom = require("lualine.themes.base16")
    custom.normal.a.bg = colours.normal
    custom.insert.a.bg = colours.insert
    custom.visual.a.bg = colours.visual
    custom.command.a.bg = colours.command
    custom.replace.a.bg = colours.replace

    local Util = require("lazyvim.util")
    local icons = require("lazyvim.config").icons
    local lualine_require = require("lualine_require")
    lualine_require.require = require

    vim.o.laststatus = vim.g.lualine_laststatus

    return {
      options = {
        theme = custom,
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },
        lualine_c = {
          Util.lualine.root_dir({ cwd = true }),
        },
        lualine_x = {
          -- stylua: ignore
          {
            function() return require("noice").api.status.command.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
            color = Util.ui.fg("Statement"),
          },
          -- stylua: ignore
          {
            function() return require("package-info").get_status() end,
          },
          -- stylua: ignore
          {
            function()
              local venv_name = require("venv-selector").get_active_venv()
              if venv_name ~= nil then
                local venv = string.gsub(venv_name, ".*/pypoetry/virtualenvs/", "(poetry) ")
                venv = string.gsub(venv_name, "\\.venv", "")
                return "env: " .. venv
              else
                return "env: none"
              end
            end,
            cond = function() return vim.bo.filetype == "python" end,
            on_click = function() require("venv-selector").open() end,
            color = Util.ui.fg("Statement"),
          },
          {
            function()
              return vim.api.nvim_call_function("codeium#GetStatusString", {})
            end,
            icon = "󱙺",
            color = { fg = colours.bufVisible },
            on_click = function()
              return vim.fn["codeium#Chat"]()
            end,
          },
        },
        lualine_y = {
          -- stylua: ignore
          {
            function() return require("noice").api.status.mode.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
            color = Util.ui.fg("Constant"),
          },
          -- stylua: ignore
          {
            function() return "  " .. require("dap").status() end,
            cond = function () return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = Util.ui.fg("Debug"),
          },
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = Util.ui.fg("Special"),
          },
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
        },
        lualine_z = {
          { "location", padding = { left = 0, right = 1 } },
          { "progress", separator = " ", padding = { left = 1, right = 1 } },
        },
      },
      extensions = { "neo-tree", "lazy", "aerial" },
    }
  end,
}

return M
