return {
  "max397574/better-escape.nvim",
  event = "InsertEnter",
  opts = {
    timeout = vim.o.timeoutlen,
    mappings = {
      i = {
        k = {
          j = "<Esc>",
        },
      },
      t = {
        k = {
          j = "<Esc>",
        },
      },
    },
  },
}
