return {
  {
    "uga-rosa/ccc.nvim",
    event = "LazyFile",
    opts = function()
      local ccc = require("ccc")
      return {
        default_color = "#408080",
        auto_close = true,
        preserve = true,
        save_on_quit = true,
        highlighter = {
          auto_enable = false, --- use just for color picker, no highlighting
        },
        recognize = {
          input = false,
          output = true,
        },
        inputs = {
          ccc.input.hsl,
          ccc.input.rgb,
        },
        outputs = {
          ccc.output.hex,
          ccc.output.css_rgb,
          ccc.output.css_hsl,
        },
      }
    end,
  },
  {
    "brenoprata10/nvim-highlight-colors",
    event = "LazyFile",
    opts = {
      --- 'background'|'foreground'|'virtual'
      render = "virtual",

      ---Set virtual symbol (requires render to be set to 'virtual')
      virtual_symbol = "■",

      ---Set virtual symbol suffix (defaults to '')
      virtual_symbol_prefix = "",

      ---Set virtual symbol suffix (defaults to ' ')
      virtual_symbol_suffix = " ",

      ---Set virtual symbol position()
      ---inline mimics VS Code style
      ---eol stands for `end of column` - Recommended to set `virtual_symbol_suffix = ''` when used.
      ---eow stands for `end of word` - Recommended to set `virtual_symbol_prefix = ' ' and virtual_symbol_suffix = ''` when used.
      virtual_symbol_position = "inline",

      ---Highlight hex colors, e.g. '#FFFFFF'
      enable_hex = true,

      ---Highlight short hex colors e.g. '#fff'
      enable_short_hex = true,

      ---Highlight rgb colors, e.g. 'rgb(0 0 0)'
      enable_rgb = true,

      ---Highlight hsl colors, e.g. 'hsl(150deg 30% 40%)'
      enable_hsl = true,

      ---Highlight CSS variables, e.g. 'var(--testing-color)'
      enable_var_usage = true,

      ---Highlight named colors, e.g. 'green'
      enable_named_colors = true,

      ---Highlight tailwind colors, e.g. 'bg-blue-500'
      enable_tailwind = true,

      -- Exclude filetypes or buftypes from highlighting e.g. 'exclude_buftypes = {'text'}'
      exclude_filetypes = { "lazy" },
      exclude_buftypes = { "text" },
    },
  },
}
