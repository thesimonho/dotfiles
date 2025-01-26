local utils = require("utils.general")

local function get_lsp_clients()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end
  return table.concat(client_names, ", ")
end

--- Conditionally hide content based on number of window splits.
-- @param n_split number: The number of horizontal splits to divide the screen into. Defaults to half the screen if nil.
-- @return function: A function that returns `true` if the window width exceeds the size of the split, otherwise `false`.
local function hide_on_split(n_split)
  n_split = n_split or 2

  return function()
    return utils.get_split_count() < n_split
  end
end

local M = {
  "nvim-lualine/lualine.nvim",
  opts = function()
    local kanagawa_paper = require("lualine.themes.kanagawa-paper")
    local utils = require("utils.general")
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
            cond = hide_on_split(3),
            on_click = function()
              utils.get_projects()
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
            cond = hide_on_split(3),
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
              local component_limit = 2
              local num_components = math.max(0, component_limit - utils.get_split_count() + 1)
              local custom_sep = " >"

              local path = vim.fn.expand("%:h"):gsub(utils.get_path_sep(), custom_sep)
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
            end,
            cond = hide_on_split(3),
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
              vim.cmd("Neotree position=float")
            end,
          },
        },
        lualine_x = {
          { "encoding", cond = hide_on_split(2) },
          {
            function()
              return require("package-info").get_status()
            end,
            cond = hide_on_split(3),
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
            color = { fg = Snacks.util.color("ErrorMsg") },
            padding = { left = 0, right = 1 },
          },
          {
            get_lsp_clients,
            cond = function()
              return vim.bo.filetype ~= "lspinfo" and hide_on_split(2)()
            end,
            on_click = function()
              vim.cmd("LspInfo")
            end,
            icon = "󰌘",
            color = { fg = Snacks.util.color("Character") },
          },
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
            cond = hide_on_split(4),
            on_click = function()
              vim.cmd("Trouble diagnostics toggle filter.buf=0")
            end,
          },
        },
        lualine_z = {
          {
            "location",
            cond = hide_on_split(2),
            separator = { left = "", right = "" },
            padding = { left = 1, right = 0 },
          },
          {
            "progress",
            separator = { left = "", right = "" },
          },
        },
      },
      inactive_sections = {
        lualine_a = {
          function()
            return "▌"
          end,
        },
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
            color = { fg = Snacks.util.color("Statement") },
          },
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      extensions = { "neo-tree", "lazy", "mason", "toggleterm", "trouble", "fzf", "nvim-dap-ui", "quickfix" },
    }
  end,
}

return M
