return {
  "danymat/neogen",
  cmd = "Neogen",
  config = true,
  version = "*",
  keys = {
    { "<leader>cD", "<cmd>lua require('neogen').generate()<CR>", desc = "Generate docs" },
  },
  opts = {
    snippet_engine = "luasnip",
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
