local M = {
  "nvim-lualine/lualine.nvim",
  opts = function()
    local colours = require("config/colours")
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
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
      },
      sections = {
        lualine_a = {
          -- stylua: ignore
          {
            "mode",
            separator = { left = "" , right = ""},
            padding = 1,
            fmt = function(str)
              return str:lower()
            end,
          },
        },
        lualine_b = {
          {
            "branch",
            on_click = function()
              LazyVim.lazygit({ cwd = LazyVim.root.git() })
            end,
          },
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
          { "filetype", icon_only = true, separator = { right = "" }, padding = { left = 1, right = 0 } },
          {
            "filename",
            file_status = true, -- Displays file status (readonly status, modified status)
            shorting_target = 60, -- Shortens path to leave 40 spaces in the window
            path = 1, -- 0: Just the filename
            -- 1: Relative path
            -- 2: Absolute path
            -- 3: Absolute path, with tilde as the home directory
            -- 4: Filename and parent dir, with tilde as the home directory
            padding = { left = 0, right = 1 },
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
              local venv_name = require("venv-selector").get_active_venv()
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
            color = { fg = colours.bufVisible },
            on_click = function()
              return vim.fn["codeium#Chat"]()
            end,
          },
        },
        lualine_y = {
          {
            "overseer",
            on_click = function()
              require("overseer").toggle()
            end,
          },
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
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
            on_click = function()
              require("trouble").toggle("workspace_diagnostics")
            end,
          },
        },
        lualine_z = {
          { "location", padding = { left = 0, right = 1 } },
          { "progress", separator = { right = "" } },
        },
      },
      extensions = { "neo-tree", "lazy", "mason", "overseer", "toggleterm", "trouble" },
    }
  end,
}

return M
