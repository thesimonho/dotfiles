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
    "sindrets/diffview.nvim",
    event = "LazyFile",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    },
    opts = {
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
        keymaps = {
          view = {
            {
              "n",
              "<leader>gmo",
              '<cmd>lua require("diffview.actions").conflict_choose("ours")<cr>',
              { desc = "Choose the OURS version of a conflict" },
            },
            {
              "n",
              "<leader>gmt",
              '<cmd>lua require("diffview.actions").conflict_choose("theirs")<cr>',
              { desc = "Choose the THEIRS version of a conflict" },
            },
            {
              "n",
              "<leader>gmb",
              '<cmd>lua require("diffview.actions").conflict_choose("base")<cr>',
              { desc = "Choose the BASE version of a conflict" },
            },
            {
              "n",
              "<leader>gma",
              '<cmd>lua require("diffview.actions").conflict_choose("all")<cr>',
              { desc = "Choose all the versions of a conflict" },
            },
            {
              "n",
              "<leader>gmx",
              '<cmd>lua require("diffview.actions").conflict_choose("none")<cr>',
              { desc = "Delete the conflict region" },
            },
            {
              "n",
              "<leader>gmO",
              '<cmd>lua require("diffview.actions").conflict_choose_all("ours")<cr>',
              { desc = "Choose the OURS version of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmT",
              '<cmd>lua require("diffview.actions").conflict_choose_all("theirs")<cr>',
              { desc = "Choose the THEIRS version of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmB",
              '<cmd>lua require("diffview.actions").conflict_choose_all("base")<cr>',
              { desc = "Choose the BASE version of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmA",
              '<cmd>lua require("diffview.actions").conflict_choose_all("all")<cr>',
              { desc = "Choose all the versions of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmX",
              '<cmd>lua require("diffview.actions").conflict_choose_all("none")<cr>',
              { desc = "Delete the conflict region for the whole file" },
            },
          },
          file_panel = {
            {
              "n",
              "<leader>gmO",
              '<cmd>lua require("diffview.actions").conflict_choose_all("ours")<cr>',
              { desc = "Choose the OURS version of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmT",
              '<cmd>lua require("diffview.actions").conflict_choose_all("theirs")<cr>',
              { desc = "Choose the THEIRS version of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmB",
              '<cmd>lua require("diffview.actions").conflict_choose_all("base")<cr>',
              { desc = "Choose the BASE version of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmA",
              '<cmd>lua require("diffview.actions").conflict_choose_all("all")<cr>',
              { desc = "Choose all the versions of a conflict for the whole file" },
            },
            {
              "n",
              "<leader>gmX",
              '<cmd>lua require("diffview.actions").conflict_choose_all("none")<cr>',
              { desc = "Delete the conflict region for the whole file" },
            },
          },
        },
      },
    },
  },
}
