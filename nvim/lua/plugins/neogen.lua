return {
  "danymat/neogen",
  init = function()
    local wk = require("which-key")
    wk.add({ "<leader>cn", icon = "", desc = "Neogen docs" })
  end,
  opts = {
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
