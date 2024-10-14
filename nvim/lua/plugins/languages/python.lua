local utils = require("utils.general")
local hooks = require("venv-selector.hooks")

local function shorten_path(filename)
  local parts = {}
  for part in string.gmatch(filename, "[^" .. utils.get_path_sep() .. "]+") do
    table.insert(parts, part)
  end
  local last_parts = table.concat(parts, utils.get_path_sep(), #parts - 2, #parts)
  return last_parts
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            pyright = {
              disableOrganizeImports = true, -- Using Ruff
            },
          },
        },
      },
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    cmd = { "VenvSelect" },
    ft = { "python" },
    keys = {
      { "<leader>cv", vim.NIL },
      { "<localleader>v", "<cmd>VenvSelect<cr>", ft = { "python" }, desc = "virtualenv" },
    },
    opts = {
      settings = {
        hooks = { hooks.pyright_hook },
        options = {
          enable_default_searches = true,
          enable_cached_venvs = true,
          activate_venv_in_terminal = true,
          set_environment_variables = true,
          show_telescope_search_type = true,
          notify_user_on_venv_activation = false,
          on_venv_activate_callback = nil,
          on_telescope_result_callback = shorten_path,
        },
      },
    },
  },
}
