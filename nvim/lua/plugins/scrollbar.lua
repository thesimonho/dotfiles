local constants = require("config/constants")

local function make_patterns_for_words(words)
  local out = {}
  for _, w in ipairs(words) do
    local pattern = ("%%f[%%w_]%s%%f[^%%w_]"):format(w)
    table.insert(out, pattern)
  end
  return out
end

-- TODO: add highlight groups for merge conflicts
return {
  {
    "dstein64/nvim-scrollview",
    dependencies = { "lewis6991/gitsigns.nvim" },
    event = "LazyFile",
    init = function()
      for group, def in pairs(constants.todo_keywords) do
        vim.g["scrollview_keywords_" .. group:lower() .. "_spec"] = {
          patterns = make_patterns_for_words(def.alt),
          highlight = def.highlight,
          symbol = def.icon,
          priority = def.priority or 25,
        }
      end
    end,
    config = function(_, opts)
      require("scrollview").setup(opts)
      require("scrollview.contrib.gitsigns").setup({
        add_symbol = "▏",
        add_priority = 5,
        change_symbol = "▏",
        change_priority = 5,
        delete_symbol = "▏",
        delete_priority = 5,
      })
    end,
    opts = {
      excluded_filetypes = {
        "bigfile",
        "which-key",
        "snacks_input",
        "snacks_picker_input",
        "trouble",
        "ccc-ui",
        "lazy",
      },
      visibility = "info",
      current_only = false,
      floating_windows = true,
      hide_on_cursor_intersect = true,
      signs_on_startup = {
        "conflicts",
        "cursor",
        "diagnostics",
        "keywords",
        "marks",
        "search",
        "quickfix",
      },
      signs_max_per_row = 1,
      signs_scrollbar_overlap = "over",
      cursor_priority = 100,
      diagnostics_error_symbol = "",
      diagnostics_warn_symbol = "",
      diagnostics_info_symbol = "",
      diagnostics_hint_symbol = "",
      diagnostics_severities = {
        vim.diagnostic.severity.ERROR,
        vim.diagnostic.severity.WARN,
      },
      keywords_built_ins = { "fix", "hack", "todo", "warn" },
      keywords_fix_symbol = "󱙒",
      keywords_hack_symbol = "󱝾",
      keywords_todo_symbol = "󰎛",
      keywords_warn_symbol = "󱝾",
    },
  },
}
