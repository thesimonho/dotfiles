return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        indent = {
          enabled = true, -- enable indent guides
          char = "│",
          only_scope = false, -- only show indent guides of the scope
          only_current = false, -- only show indent guides in the current window
          hl = "SnacksIndent",
        },
        scope = {
          enabled = false, -- enable highlighting the current scope
          hl = "SnacksIndentScope",
        },
        chunk = {
          enabled = true,
          only_current = true,
          hl = "SnacksIndentChunk",
          char = {
            corner_top = "╭",
            corner_bottom = "╰",
            horizontal = "─",
            vertical = "│",
            arrow = "›",
          },
        },
        filter = function(buf)
          local excluded_filetypes =
            { "help", "lazy", "mason", "mcphub", "toggleterm", "wk", "snacks_picker_preview", "qf", "noice" }
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and not vim.tbl_contains(excluded_filetypes, vim.bo[buf].filetype)
        end,
        priority = 200,
      },
    },
  },
}
