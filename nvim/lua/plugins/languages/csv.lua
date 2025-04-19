return {
  {
    "hat0uma/csvview.nvim",
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    ft = { "csv", "tsv" },
    keys = {
      { "<localleader>v", "<cmd>CsvViewToggle<cr>", ft = { "csv", "tsv" }, desc = "Toggle CSV View" },
    },
    init = function()
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        pattern = { "*.csv", "*.tsv" },
        callback = function()
          vim.cmd("CsvViewToggle")
        end,
      })
    end,
    opts = {
      view = {
        display_mode = "border",
        header_lnum = 1,
      },
      keymaps = {
        -- Text objects for selecting fields
        textobject_field_inner = { "iC", mode = { "o", "x" } },
        textobject_field_outer = { "aC", mode = { "o", "x" } },
        -- Excel-like navigation:
        -- Use <Tab> and <S-Tab> to move horizontally between fields.
        -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
        -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
  },
}
