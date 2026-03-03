return {
  {
    "uga-rosa/ccc.nvim",
    event = "LazyFile",
    opts = function()
      local ccc = require("ccc")
      local mapping = ccc.mapping
      return {
        default_color = "#636363",
        auto_close = true,
        preserve = true,
        alpha_show = "auto",
        save_on_quit = true,
        highlighter = {
          auto_enable = false,
        },
        highlight_mode = "virtual",
        virtual_symbol = "󰝤 ",
        virtual_pos = "inline-left",
        recognize = {
          input = false,
          output = true,
        },
        inputs = {
          ccc.input.oklch,
          ccc.input.hsl,
          ccc.input.rgb,
        },
        outputs = {
          ccc.output.css_oklch,
          ccc.output.hex,
          ccc.output.css_hsl,
          ccc.output.css_rgb,
        },
        output_line = function(before_color, after_color)
          local b_hex = before_color:hex()
          local a_str = after_color:str()
          local line = b_hex .. " -> " .. a_str
          -- Range for highlight
          local b_start_col = 0
          local b_end_col = #b_hex
          local a_start_col = b_end_col + 4
          local a_end_col = a_start_col + #a_str
          return line, b_start_col, b_end_col, a_start_col, a_end_col
        end,
        mappings = {
          ["l"] = mapping.increase1,
          ["L"] = mapping.increase10,
          ["h"] = mapping.decrease1,
          ["H"] = mapping.decrease10,
          ["`"] = mapping.set0,
          ["5"] = mapping.set50,
          ["0"] = mapping.set100,
        },
      }
    end,
  },
  {
    "catgoose/nvim-colorizer.lua",
    event = "VeryLazy",
    opts = {
      filetypes = {
        "*",
        "!bigfile",
        "!lazy",
        "!ccc-ui",
      },
      buftypes = {
        "*",
        "!terminal",
      },
      lazy_load = true,
      options = {
        parsers = {
          names = {
            enable = true,
            lowercase = true,
            camelcase = true,
            uppercase = true,
            strip_digits = true,
          },
          hex = {
            default = false, -- default value for format keys (see above)
            rgb = true, -- #RGB
            rgba = true, -- #RGBA
            rrggbb = true, -- #RRGGBB
            rrggbbaa = true, -- #RRGGBBAA
            aarrggbb = true, -- 0xAARRGGBB
          },
          rgb = { enable = true },
          hsl = { enable = true },
          oklch = { enable = true },
          tailwind = {
            enable = true,
            lsp = true,
            update_names = true,
          },
          sass = {
            enable = true,
            parsers = { css = true },
            variable_pattern = "^%$([%w_-]+)",
          },
          xterm = { enable = true },
        },
        display = {
          mode = "virtualtext", -- "background"|"foreground"|"virtualtext"
          background = {
            bright_fg = "#000000",
            dark_fg = "#ffffff",
          },
          virtualtext = {
            char = "󰝤",
            position = "before", -- "eol"|"before"|"after"
            hl_mode = "foreground",
          },
        },
        always_update = true,
      },
    },
  },
}
