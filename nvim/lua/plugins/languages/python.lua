local os_utils = require("utils.os")
if not os_utils.has_executable("python") then
  return {}
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
}
