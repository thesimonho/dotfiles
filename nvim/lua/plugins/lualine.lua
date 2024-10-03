return {
  "nvim-lualine/lualine.nvim",
  opts = function()
    local kanagawa_paper = require("lualine.themes.kanagawa-paper")
    local utils = require("config.utils")
    local Util = require("lazyvim.util")
    local icons = require("lazyvim.config").icons
    local lualine_require = require("lualine_require")
    lualine_require.require = require

    vim.o.laststatus = vim.g.lualine_laststatus

    return {
      options = {
        theme = kanagawa_paper,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        globalstatus = false,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
      },
      sections = {
        lualine_a = {
          -- stylua: ignore
          {
            "mode",
            separator = { left = "" , right = ""},
            fmt = function(str)
              return str:lower()
            end,
          },
        },
        lualine_b = {
          {
            function()
              return " " .. vim.g.git_worktree_root
            end,
            cond = function()
              return vim.g.git_worktree ~= nil
            end,
            padding = { left = 1, right = 0 },
            separator = { right = "" },
          },
          {
            "branch",
            on_click = function()
              LazyVim.lazygit({ cwd = LazyVim.root.git() })
            end,
            padding = { left = 1, right = 1 },
          },
          {
            "diff",
            padding = { left = 1, right = 0 },
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
          {
            "filetype",
            icon_only = true,
            separator = "",
            padding = { left = 1, right = 0 },
          },
          {
            function()
              return vim.fn.expand("%:h") .. utils.get_path_sep()
            end,
            separator = "",
            padding = 0,
          },
          {
            "filename",
            file_status = true,
            path = 0,
            padding = 0,
            color = Util.ui.fg("Statement"),
          },
        },
        lualine_x = {
          -- stylua: ignore
          {
            function() return require("package-info").get_status() end,
          },
          -- stylua: ignore
          {
            function()
              local venv_name = require("venv-selector").venv()
              if venv_name ~= nil then
                local venv = vim.fn.fnamemodify(venv_name, ":t")
                local parts = {}
                for part in venv:gmatch("[^%-]+") do
                  table.insert(parts, part)
                end
                table.remove(parts, #parts)
                table.remove(parts, #parts)
                return "env: " .. table.concat(parts, "-")
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
            on_click = function()
              return vim.fn["codeium#Chat"]()
            end,
          },
        },
        lualine_y = {
          -- stylua: ignore
          {
            function() return "🔴 " .. require("noice").api.status.mode.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
            color = Util.ui.fg("ErrorMsg"),
            padding = {left = 0, right = 1}
          },
          -- stylua: ignore
          {
            function() return "  " .. require("dap").status() end,
            cond = function () return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = Util.ui.fg("Debug"),
          },
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
            on_click = function()
              vim.cmd("Trouble diagnostics toggle filter.buf=0")
            end,
          },
        },
        lualine_z = {
          { "progress", separator = { left = "", right = "" } },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filetype",
            icon_only = true,
            colored = false,
            separator = { right = "" },
            padding = { left = 1, right = 0 },
          },
          {
            function()
              return vim.fn.expand("%:h") .. utils.get_path_sep()
            end,
            separator = "",
            padding = 0,
          },
          {
            "filename",
            file_status = true,
            path = 0,
            padding = 0,
            color = Util.ui.fg("Statement"),
          },
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      extensions = { "neo-tree", "lazy", "mason", "toggleterm", "trouble" },
    }
  end,
}
