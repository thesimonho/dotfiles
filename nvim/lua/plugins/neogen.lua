return {
  "danymat/neogen",
  init = function()
    local wk = require("which-key")
    wk.add({ "<leader>cn", icon = "", desc = "Neogen docs" })
  end,
  keys = {
    { "<leader>cn", vim.NIL },
    {
      "<leader>cnf",
      "<cmd>lua require('neogen').generate({type = 'func'})<cr>",
      desc = "Function",
    },
    {
      "<leader>cnF",
      "<cmd>lua require('neogen').generate({type = 'file'})<cr>",
      desc = "File",
    },
    {
      "<leader>cnc",
      "<cmd>lua require('neogen').generate({type = 'class'})<cr>",
      desc = "Class",
    },
    {
      "<leader>cnt",
      "<cmd>lua require('neogen').generate({type = 'type'})<cr>",
      desc = "Type",
    },
  },
  opts = {
    snippet_engine = "nvim",
    languages = {
      python = {
        template = {
          annotation_convention = "google_docstrings",
        },
      },
      typescript = {
        template = {
          annotation_convention = "tsdoc",
        },
      },
      typescriptreact = {
        template = {
          annotation_convention = "tsdoc",
        },
      },
    },
  },
}
