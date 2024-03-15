local M = {
  "nvim-telescope/telescope.nvim",
  enabled = true,
  dependencies = {
    "nvim-telescope/telescope-project.nvim",
  },
  cmd = "Telescope",
  keys = {
    { "<leader>,", vim.NIL },
    { "<leader>:", vim.NIL },
    { "<leader>/", vim.NIL },
    { "<leader><space>", vim.NIL },
    { "<leader>fb", vim.NIL },
    { "<leader>sd", vim.NIL },
    { "<leader>sD", vim.NIL },
    { "<leader>sg", vim.NIL },
    { "<leader>sG", vim.NIL },
    { "<leader>ss", vim.NIL },
    { "<leader>sS", vim.NIL },
    { "<leader>fg", vim.NIL },
    { "<leader>fg", require("lazyvim.util").telescope("live_grep"), desc = "Grep (root dir)" },
    { "<leader>p", "<cmd>lua require('telescope').extensions.project.project{}<cr>", desc = "Projects" },
  },
  opts = {
    defaults = {
      sorting_strategy = "ascending",
      scroll_strategy = "limit",
      wrap_results = false,
      dynamic_preview_title = true,
      path_display = { "smart" },
      file_ignore_patterns = {
        "node_modules",
        ".terraform",
        ".git",
        "$RECYCLE.BIN",
      },
      preview = {
        filesize_limit = 2,
        timeout = 200,
      },
      mappings = {
        i = {
          ["<C-j>"] = require("telescope.actions").move_selection_next,
          ["<C-k>"] = require("telescope.actions").move_selection_previous,
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      buffers = {
        theme = "dropdown",
        previewer = false,
        winblend = 5,
        path_display = { "smart" },
      },
    },
    extensions = {
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
      },
      project = {
        base_dirs = {
          "~",
          "D:\\",
        },
        hidden_files = false,
        theme = "dropdown",
        order_by = "recent",
        search_by = "title",
        on_project_selected = function(prompt_bufnr)
          require("telescope._extensions.project.actions").find_project_files(prompt_bufnr, false)
        end,
      },
    },
  },
}

return M
