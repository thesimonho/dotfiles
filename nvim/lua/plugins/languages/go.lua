return {
  {
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
  },
  {
    "fatih/vim-go", -- for hugo template suntax highlighting
    ft = { "gohtmltmpl" },
  },
}
