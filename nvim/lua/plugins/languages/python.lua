local utils = require("config.utils")
local function get_poetry_path()
  if utils.is_windows() then
    return os.getenv("LOCALAPPDATA") .. "\\pypoetry\\Cache\\virtualenvs"
  else
    return "~/.cache/pypoetry/virtualenvs"
  end
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
    cmd = { "VenvSelect", "VenvSelectCached" },
    ft = "python",
    keys = {
      { "<leader>cv", vim.NIL },
      { "<localleader>v", "<cmd>VenvSelectCached<cr>", ft = "python", desc = "virtualenv (cached)" },
      { "<localleader>V", "<cmd>VenvSelect<cr>", ft = "python", desc = "virtualenv (select)" },
    },
    opts = {
      poetry_path = get_poetry_path(),
      notify_user_on_activate = false,
      changed_venv_hooks = {
        require("venv-selector").hooks.pyright,
        require("venv-selector").hooks.pylsp,
      },
    },
  },
}
