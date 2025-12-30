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
      lazy_load = true,
      user_default_options = {
        names = true,
        names_opts = {
          lowercase = true, -- name:lower(), highlight `blue` and `red`
          camelcase = true, -- name, highlight `Blue` and `Red`
          uppercase = true, -- name:upper(), highlight `BLUE` and `RED`
          strip_digits = true, -- ignore names with digits,
        },
        RGB = true, -- #RGB hex codes
        RGBA = true, -- #RGBA hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        oklch_fn = true, -- CSS oklch() function
        tailwind = "both",
        tailwind_opts = {
          update_names = true, -- update tailwind names from LSP results.
        },
        sass = { enable = true, parsers = { "css" } }, -- Enable sass colors
        xterm = true, -- Enable xterm 256-color codes (#xNN, \e[38;5;NNNm)
        mode = "virtualtext",
        virtualtext = "󰝤",
        virtualtext_inline = "before",
        virtualtext_mode = "foreground",
        always_update = true,
      },
    },
  },
}
