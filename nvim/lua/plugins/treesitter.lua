return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "comment",
        "cpp",
        "css",
        "gitignore",
        "graphql",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "latex",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rst",
        "scss",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      auto_install = true, -- disable if no tree-sitter cli installed
      ignore_install = {}, -- list of parsers to ignore installing
      indent = { enable = true },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      incremental_selection = {
        enable = false, -- use flash treesitter mode instead
      },
      textobjects = {
        swap = {
          enable = true,
          swap_next = {
            ["<leader>cx"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>cX"] = "@parameter.inner",
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.md",
        callback = function()
          require("treesitter-context").disable()
        end,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          if not vim.fn.expand("%:e"):match("^md$") then
            require("treesitter-context").enable()
          end
        end,
      })
    end,
    keys = {
      {
        "gC",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Go to Treesitter Context",
      },
    },
    opts = {
      multiwindow = false, -- Enable multiwindow support.
      max_lines = 5, -- How many lines the window should span. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 3, -- Maximum number of lines to show for a single context
      trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = "topline", -- Line used to calculate context. Choices: 'cursor', 'topline'
    },
  },
}
