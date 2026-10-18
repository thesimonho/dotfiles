return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Oxfmt also supports Prettier's web/document filetypes beyond the Oxc extra's list.
      for _, formatters in pairs(opts.formatters_by_ft) do
        if type(formatters) == "table" and vim.tbl_contains(formatters, "prettier") then
          if not vim.tbl_contains(formatters, "oxfmt") then
            table.insert(formatters, "oxfmt")
          end
        end
      end
      local oxfmt_markers = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }
      local function has_oxfmt_config(ctx)
        return vim.fs.root(ctx.dirname, oxfmt_markers) ~= nil
      end

      -- Include config files and the package.json prettier field using Conform's discovery.
      local prettier = require("conform.formatters.prettier")
      local prettier_condition = opts.formatters.prettier.condition
      opts.formatters.prettier.condition = function(self, ctx)
        return prettier_condition(self, ctx) and (prettier.cwd(self, ctx) ~= nil or not has_oxfmt_config(ctx))
      end
      opts.formatters.oxfmt = vim.tbl_deep_extend("force", opts.formatters.oxfmt or {}, {
        condition = function(_, ctx)
          return has_oxfmt_config(ctx)
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        oxlint = {
          -- Include package-level configs instead of only checking the Git root.
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" })
            if root then
              on_dir(root)
            end
          end,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "js-debug-adapter",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "jsdoc",
        "javascript",
        "typescript",
      },
    },
  },
}
