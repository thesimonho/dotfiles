return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      gopls = {
        keys = {
          { "<leader>td", vim.NIL },
        },
      },
    },
  },
}
