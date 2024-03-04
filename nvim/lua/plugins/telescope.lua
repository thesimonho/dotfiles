local M = {
  "nvim-telescope/telescope.nvim",
  enabled = true,
  dependencies = {
    "nvim-telescope/telescope-project.nvim",
  },
  cmd = "Telescope",
  keys = {
    { "<leader>,", vim.NIL },
    { "<leader>p", "<cmd>lua require('telescope').extensions.project.project{}<cr>", desc = "Projects" },
    { "<leader>bb", "<cmd>Telescope buffers<cr>", { noremap = true, silent = true, desc = "Buffer List" } },
  },
  opts = {
    defaults = {
      sorting_strategy = "ascending",
      scroll_strategy = "limit",
      wrap_results = false,
      dynamic_preview_title = true,
      file_ignore_patterns = {
        "node_modules",
        ".terraform",
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
          -- require("telescope._extensions.project.actions").change_working_directory(prompt_bufnr)
        end,
      },
    },
  },
}

return M
