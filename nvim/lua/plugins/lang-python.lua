--- Set environments variables after changing virtualenv
--- @param venv_path string A string containing the absolute path to selected virtualenv
--- @param venv_python string A string containing the absolute path to python binary in selected venv
local function set_env_hook(venv_path, venv_python)
  vim.env.VIRTUAL_ENV = venv_path
  vim.env.PYTHONPATH = venv_python
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
    cmd = "VenvSelect",
    ft = "python",
    keys = {
      { "<leader>cv", vim.NIL },
      { "<localleader>v", "<cmd>VenvSelectCached<cr>", ft = "python", desc = "virtualenv (cached)" },
      { "<localleader>V", "<cmd>VenvSelect<cr>", ft = "python", desc = "virtualenv (select)" },
    },
    opts = {
      poetry_path = os.getenv("LOCALAPPDATA") .. "\\pypoetry\\Cache\\virtualenvs",
      notify_user_on_activate = false,
      changed_venv_hooks = {
        -- set_env_hook,
        require("venv-selector").hooks.pyright,
        require("venv-selector").hooks.pylsp,
      },
    },
  },
}
