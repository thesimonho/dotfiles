return {
  {
    "danymat/neogen",
    opts = {
      snippet_engine = "nvim",
      languages = {
        python = {
          template = { annotation_convention = "google_docstrings" },
        },
        typescript = {
          template = { annotation_convention = "tsdoc" },
        },
        typescriptreact = {
          template = { annotation_convention = "tsdoc" },
        },
      },
    },
  },
}
