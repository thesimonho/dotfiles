return {
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>gh"] = { name = "Hunks" },
        ["<leader>gm"] = { name = "Merge conflict" },
      },
    },
  },
  {
    "pwntester/octo.nvim",
    opts = {
      ssh_aliases = { ["personal-github.com"] = "github.com" },
    },
  },
  {
    "sindrets/diffview.nvim",
    event = "LazyFile",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    },
    opts = function()
      local actions = require("diffview.config").actions
      return {
        enhanced_diff_hl = true,
        view = {
          default = {
            -- Config for changed files, and staged files in diff views.
            layout = "diff2_horizontal",
            winbar_info = true,
          },
          merge_tool = {
            -- Config for conflicted files in diff views during a merge or rebase.
            layout = "diff3_mixed",
            disable_diagnostics = true,
            winbar_info = true,
          },
          file_history = {
            -- Config for changed files in file history views.
            layout = "diff2_horizontal",
            winbar_info = true,
          },
        },
        keymaps = {
          disable_defaults = true,
          view = {
            {
              "n",
              "<tab>",
              actions.select_next_entry,
              { desc = "Open the diff for the next file" },
            },
            {
              "n",
              "<s-tab>",
              actions.select_prev_entry,
              { desc = "Open the diff for the previous file" },
            },
            {
              "n",
              "gf",
              actions.goto_file_edit,
              { desc = "Open the file in the previous tabpage" },
            },
            {
              "n",
              "<leader>e",
              actions.toggle_files,
              { desc = "Toggle the file panel." },
            },
            {
              "n",
              "[x",
              actions.prev_conflict,
              { desc = "In the merge-tool: jump to the previous conflict" },
            },
            {
              "n",
              "]x",
              actions.next_conflict,
              { desc = "In the merge-tool: jump to the next conflict" },
            },
            {
              "n",
              "<leader>gmo",
              actions.conflict_choose("ours"),
              { desc = "Choose the OURS version" },
            },
            {
              "n",
              "<leader>gmt",
              actions.conflict_choose("theirs"),
              { desc = "Choose the THEIRS version" },
            },
            {
              "n",
              "<leader>gmb",
              actions.conflict_choose("base"),
              { desc = "Choose the BASE version" },
            },
            {
              "n",
              "<leader>gma",
              actions.conflict_choose("all"),
              { desc = "Choose all the versions" },
            },
            {
              "n",
              "<leader>gmx",
              actions.conflict_choose("none"),
              { desc = "Delete the conflict region" },
            },
            {
              "n",
              "<leader>gmO",
              actions.conflict_choose_all("ours"),
              { desc = "Choose the OURS version for the whole file" },
            },
            {
              "n",
              "<leader>gmT",
              actions.conflict_choose_all("theirs"),
              { desc = "Choose the THEIRS version for the whole file" },
            },
            {
              "n",
              "<leader>gmB",
              actions.conflict_choose_all("base"),
              { desc = "Choose the BASE version for the whole file" },
            },
            {
              "n",
              "<leader>gmA",
              actions.conflict_choose_all("all"),
              { desc = "Choose all the versions for the whole file" },
            },
            {
              "n",
              "<leader>gmX",
              actions.conflict_choose_all("none"),
              { desc = "Delete the conflict region for the whole file" },
            },
          },
          diff1 = {
            {
              "n",
              "g?",
              actions.help({ "view", "diff1" }),
              { desc = "Open the help panel" },
            },
          },
          diff2 = {
            {
              "n",
              "g?",
              actions.help({ "view", "diff2" }),
              { desc = "Open the help panel" },
            },
          },
          diff3 = {
            {
              "n",
              "g?",
              actions.help({ "view", "diff3" }),
              { desc = "Open the help panel" },
            },
          },
          diff4 = {
            {
              "n",
              "g?",
              actions.help({ "view", "diff4" }),
              { desc = "Open the help panel" },
            },
          },
          file_panel = {
            {
              "n",
              "<cr>",
              actions.select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            {
              "n",
              "<2-LeftMouse>",
              actions.select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            {
              "n",
              "<space>",
              actions.toggle_stage_entry,
              { desc = "Stage / unstage the selected entry" },
            },
            { "n", "za", actions.toggle_fold, { desc = "Toggle fold" } },
            { "n", "zR", actions.open_all_folds, { desc = "Expand all folds" } },
            { "n", "zM", actions.close_all_folds, { desc = "Collapse all folds" } },
            {
              "n",
              "<tab>",
              actions.select_next_entry,
              { desc = "Open the diff for the next file" },
            },
            {
              "n",
              "<s-tab>",
              actions.select_prev_entry,
              { desc = "Open the diff for the previous file" },
            },
            {
              "n",
              "gf",
              actions.goto_file_edit,
              { desc = "Open the file in the previous tabpage" },
            },
            {
              "n",
              "R",
              actions.refresh_files,
              { desc = "Update stats and entries in the file list" },
            },
            {
              "n",
              "<leader>e",
              actions.toggle_files,
              { desc = "Toggle the file panel" },
            },
            {
              "n",
              "[x",
              actions.prev_conflict,
              { desc = "Go to the previous conflict" },
            },
            {
              "n",
              "]x",
              actions.next_conflict,
              { desc = "Go to the next conflict" },
            },
            {
              "n",
              "g?",
              actions.help("file_panel"),
              { desc = "Open the help panel" },
            },
            {
              "n",
              "<leader>gmO",
              actions.conflict_choose_all("ours"),
              { desc = "Choose the OURS version for the whole file" },
            },
            {
              "n",
              "<leader>gmT",
              actions.conflict_choose_all("theirs"),
              { desc = "Choose the THEIRS version for the whole file" },
            },
            {
              "n",
              "<leader>gmB",
              actions.conflict_choose_all("base"),
              { desc = "Choose the BASE version for the whole file" },
            },
            {
              "n",
              "<leader>gmA",
              actions.conflict_choose_all("all"),
              { desc = "Choose all the versions for the whole file" },
            },
            {
              "n",
              "<leader>gmX",
              actions.conflict_choose_all("none"),
              { desc = "Delete the conflict region for the whole file" },
            },
          },
          file_history_panel = {
            { "n", "g!", actions.options, { desc = "Open the option panel" } },
            {
              "n",
              "y",
              actions.copy_hash,
              { desc = "Copy the commit hash of the entry under the cursor" },
            },
            { "n", "za", actions.toggle_fold, { desc = "Toggle fold" } },
            { "n", "zR", actions.open_all_folds, { desc = "Expand all folds" } },
            { "n", "zM", actions.close_all_folds, { desc = "Collapse all folds" } },
            {
              "n",
              "<cr>",
              actions.select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            {
              "n",
              "<2-LeftMouse>",
              actions.select_entry,
              { desc = "Open the diff for the selected entry" },
            },
            {
              "n",
              "<tab>",
              actions.select_next_entry,
              { desc = "Open the diff for the next file" },
            },
            {
              "n",
              "<s-tab>",
              actions.select_prev_entry,
              { desc = "Open the diff for the previous file" },
            },
            {
              "n",
              "gf",
              actions.goto_file_edit,
              { desc = "Open the file in the previous tabpage" },
            },
            {
              "n",
              "<leader>e",
              actions.toggle_files,
              { desc = "Toggle the file panel" },
            },
            {
              "n",
              "g?",
              actions.help("file_history_panel"),
              { desc = "Open the help panel" },
            },
          },
          option_panel = {
            {
              "n",
              "<space>",
              actions.select_entry,
              { desc = "Change the current option" },
            },
            { "n", "q", actions.close, { desc = "Close the panel" } },
            {
              "n",
              "g?",
              actions.help("option_panel"),
              { desc = "Open the help panel" },
            },
          },
          help_panel = {
            { "n", "q", actions.close, { desc = "Close help menu" } },
            { "n", "<esc>", actions.close, { desc = "Close help menu" } },
          },
        },
      }
    end,
  },
}
