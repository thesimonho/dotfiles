local git = require("utils.git")
local style = require("utils.style")
local pickers = require("utils.telescope_pickers")
local actions = require("telescope.actions")

local Project = {}

local M = {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-project.nvim",
      "debugloop/telescope-undo.nvim",
      "piersolenski/telescope-import.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>,", vim.NIL },
      { "<leader>:", vim.NIL },
      { "<leader>/", vim.NIL },
      { "<leader><space>", vim.NIL },
      { "<leader>sd", vim.NIL },
      { "<leader>sD", vim.NIL },
      { "<leader>sg", vim.NIL },
      { "<leader>sG", vim.NIL },
      { "<leader>ss", vim.NIL },
      { "<leader>sS", vim.NIL },
      { "<leader>sb", vim.NIL },
      { "<leader>sw", vim.NIL },
      { "<leader>sW", vim.NIL },
      { "<leader>sw", vim.NIL, mode = "v" },
      { "<leader>sW", vim.NIL, mode = "v" },
      {
        "<leader>ff",
        function()
          pickers.prettyFilesPicker({ picker = "find_files" })
        end,
        desc = "Find Files",
      },
      {
        "<leader>fr",
        function()
          pickers.prettyFilesPicker({ picker = "oldfiles" })
        end,
        desc = "Recent Files",
      },
      {
        "<leader>fw",
        function()
          pickers.prettyGrepPicker({
            picker = "grep_string",
            options = {
              root = true,
              word_match = "-w",
            },
          })
        end,
        desc = "Find Word",
      },
      {
        "<leader>fw",
        function()
          pickers.prettyGrepPicker({
            picker = "grep_string",
            options = { root = true },
          })
        end,
        mode = "v",
        desc = "Find Selection",
      },
      {
        "<leader>fg",
        function()
          pickers.prettyGrepPicker({
            picker = "live_grep",
          })
        end,
        desc = "Grep",
      },
      { "<leader>fb", "<cmd>Telescope current_buffer_fuzzy_find<cr><cr>", desc = "Find in Buffer" },
      {
        "<leader>p",
        function()
          -- get the filetype to check whether we started in dashboard
          local bufnr = vim.api.nvim_get_current_buf()
          Project.prev_filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
          require("telescope").extensions.project.project({})
        end,
        desc = "Projects",
      },
      { "<leader>U", "<cmd>Telescope undo<cr>", desc = "Undo tree" },
      { "<leader>ci", "<cmd>Telescope import<cr>", desc = "Import" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          scroll_strategy = "limit",
          wrap_results = false,
          dynamic_preview_title = true,
          prompt_prefix = "  ",
          path_display = { "smart" },
          border = true,
          borderchars = style.border_chars_outer_thin_telescope,
          preview = {
            filesize_limit = 2,
            timeout = 200,
          },
          file_ignore_patterns = {
            "node_modules[\\/]",
            ".terraform[\\/]",
            ".git[\\/]",
            "*.lock",
            "$RECYCLE.BIN",
          },
          mappings = {
            i = {
              ["<C-j>"] = require("telescope.actions").move_selection_next,
              ["<C-k>"] = require("telescope.actions").move_selection_previous,
              ["<C-H>"] = function()
                vim.api.nvim_input("<C-w>")
              end,
              ["<c-q>"] = require("trouble.sources.telescope").open,
            },
            n = {
              ["<c-q>"] = require("trouble.sources.telescope").open,
              ["q"] = require("telescope.actions").close,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          buffers = {
            theme = "dropdown",
            previewer = true,
            path_display = { shorten = { 1, exclude = { -2, -1 } } },
            borderchars = style.border_chars_outer_thin_telescope,
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
            hidden_files = true,
            theme = "dropdown",
            order_by = "recent",
            search_by = "title",
            on_project_selected = function()
              local selected = require("telescope._extensions.project.actions").get_selected_path()
              local stat = vim.loop.fs_stat(selected .. "/.bare")

              if stat and stat.type == "directory" then
                git.switch_git_worktree(selected)
              else
                local opts = {
                  cwd = selected,
                }

                if Project.prev_filetype ~= "snacks_dashboard" then
                  opts.attach_mappings = function(bufnr)
                    actions.select_default:replace(function()
                      actions.select_tab(bufnr)
                    end)
                    return true
                  end
                end

                pickers.prettyFilesPicker({
                  picker = "find_files",
                  options = opts,
                })
              end
            end,
          },
          undo = {
            use_delta = false,
            mappings = {
              i = {
                ["<cr>"] = require("telescope-undo.actions").yank_additions,
                ["<C-y>"] = require("telescope-undo.actions").yank_deletions,
                ["<C-r>"] = require("telescope-undo.actions").restore,
              },
              n = {
                ["<cr>"] = require("telescope-undo.actions").yank_additions,
                ["<C-y>"] = require("telescope-undo.actions").yank_deletions,
                ["<C-r>"] = require("telescope-undo.actions").restore,
              },
            },
          },
          import = {
            insert_at_top = false,
          },
        },
      })
      require("telescope").load_extension("undo")
      require("telescope").load_extension("import")
    end,
  },
}

return M
