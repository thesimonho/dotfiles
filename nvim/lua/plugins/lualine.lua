local kanagawa_paper = require("lualine.themes.kanagawa-paper-ink")
local utils = require("utils.general")
local ui = require("utils.ui")
local fs = require("utils.fs")
local icons = require("lazyvim.config").icons

local function get_lsp_clients()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end
  return table.concat(client_names, ", ")
end

local function short_path(component_limit)
  component_limit = component_limit or 2
  local num_components = math.max(0, component_limit - utils.get_split_count() + 1)
  local custom_sep = " ›"

  local path = vim.fn.expand("%:h"):gsub(fs.get_path_sep(), custom_sep)
  local all_components = {}
  for part in path:gmatch("[^" .. custom_sep .. "]+") do
    table.insert(all_components, 1, part:match("^%s*(.-)%s*$"))
  end

  local components = {}
  for i = 1, #all_components do
    if #components >= num_components then
      break
    end
    table.insert(components, 1, all_components[i])
  end

  return table.concat(components, custom_sep .. " ") .. custom_sep
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      theme = kanagawa_paper,
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
      globalstatus = false,
      disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard", "starter" } },
    },
    sections = {
      lualine_a = {
        {
          "mode",
          separator = { left = "", right = "" },
          fmt = function(str)
            return str:lower()
          end,
        },
      },
      lualine_b = {
        {
          function()
            return Snacks.git.get_root():match("([^/\\]+)$")
          end,
          separator = "",
          padding = { left = 1, right = 0 },
          cond = function()
            return utils.get_split_count() < 3
          end,
          on_click = function()
            ui.show_projects_table()
            vim.defer_fn(function()
              vim.cmd("startinsert")
            end, 100)
          end,
        },
        {
          "branch",
          icon = "󰘬",
          padding = { left = 1, right = 1 },
          on_click = function()
            vim.cmd("FzfLua git_branches")
            vim.defer_fn(function()
              vim.cmd("startinsert")
            end, 100)
          end,
        },
        {
          "diff",
          padding = { left = 1, right = 0 },
          symbols = {
            added = icons.git.added,
            modified = icons.git.modified,
            removed = icons.git.removed,
          },
          cond = function()
            return utils.get_split_count() < 3
          end,
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
          on_click = function()
            Snacks.lazygit()
            vim.defer_fn(function()
              vim.cmd("startinsert")
            end, 100)
          end,
        },
      },
      lualine_c = {
        {
          function()
            return short_path(2)
          end,
          cond = function()
            return utils.get_split_count() < 3
          end,
          padding = { left = 1, right = 0 },
          separator = "",
          on_click = function()
            vim.cmd("Neotree position=float")
          end,
        },
        {
          "filetype",
          icon_only = true,
          separator = "",
          padding = { left = 1, right = 0 },
        },
        {
          "filename",
          file_status = true,
          path = 0,
          padding = 0,
          color = function()
            if vim.bo.modified then
              return { fg = kanagawa_paper.insert.a.bg }
            end
            return { fg = Snacks.util.color("Statement") }
          end,
          on_click = function()
            vim.cmd("Neotree position=float reveal=true")
          end,
        },
      },
      lualine_x = {
        {
          "encoding",
          cond = function()
            return utils.get_split_count() < 2
          end,
          on_click = function()
            local encoding = vim.api.nvim_get_option_value("fileencoding", { scope = "local" })
            vim.api.nvim_feedkeys(":set fileencoding=" .. encoding, "n", true)
          end,
        },
        {
          "fileformat",
          cond = function()
            return utils.get_split_count() < 3
          end,
          on_click = function()
            local fileformat = vim.api.nvim_get_option_value("fileformat", { scope = "local" })
            vim.api.nvim_feedkeys(":set fileformat=" .. fileformat, "n", true)
          end,
        },
        {
          function()
            return require("package-info").get_status()
          end,
          cond = function()
            return utils.get_split_count() < 3
          end,
        },
      },
      lualine_y = {
        {
          function()
            return "󰑋 " .. require("noice").api.status.mode.get()
          end,
          cond = function()
            return package.loaded["noice"] and require("noice").api.status.mode.has()
          end,
          color = function()
            return { fg = Snacks.util.color("ErrorMsg") }
          end,
          padding = { left = 0, right = 1 },
        },
        {
          get_lsp_clients,
          cond = function()
            return vim.bo.filetype ~= "lspinfo" and utils.get_split_count() < 2
          end,
          on_click = function()
            vim.cmd("LspInfo")
          end,
          icon = "󰌘",
          color = function()
            return { fg = Snacks.util.color("Character") }
          end,
        },
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
          cond = function()
            return utils.get_split_count() < 4
          end,
          on_click = function()
            vim.cmd("Trouble diagnostics toggle filter.buf=0")
          end,
        },
      },
      lualine_z = {
        {
          function()
            return utils.get_progress_char()
          end,
          color = function()
            return { fg = Snacks.util.color("lualine_b_normal", "bg") }
          end,
          separator = { left = "" },
          padding = 0,
        },
      },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        {
          function()
            return short_path(4)
          end,
          padding = { left = 1, right = 0 },
          separator = "",
        },
        {
          "filetype",
          icon_only = true,
          colored = false,
          separator = "",
          padding = { left = 1, right = 0 },
        },
        {
          "filename",
          file_status = true,
          path = 0,
          padding = 0,
          color = { fg = kanagawa_paper.visual.b.fg },
        },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {
        {
          function()
            return utils.get_progress_char()
          end,
          color = { bg = kanagawa_paper.visual.b.fg, fg = kanagawa_paper.inactive.c.bg },
          separator = { left = "" },
          padding = 0,
        },
      },
    },
    extensions = { "neo-tree", "lazy", "mason", "toggleterm", "trouble", "fzf", "nvim-dap-ui", "quickfix" },
  },
}
