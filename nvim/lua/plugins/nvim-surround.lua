return {
  "kylechui/nvim-surround",
  event = "VeryLazy",
  opts = {
    keymaps = {
      insert = "<C-g>s",
      insert_line = "<C-g>S",

      normal = "gs",
      normal_line = "gS",
      normal_cur = "gss",
      normal_cur_line = "gsS",

      visual = "gs",
      visual_line = "gS",

      delete = "gsd",
      change = "gsc",
      change_line = "gsC",
    },
    surrounds = {
      -- javascript string to interpolated string
      ["s"] = {
        add = function()
          local ts_utils = require("nvim-treesitter.ts_utils")
          local cur = ts_utils.get_node_at_cursor(0, true)
          local language = vim.bo.filetype
          local is_jsy = (
            language == "javascript"
            or language == "javascriptreact"
            or language == "typescript"
            or language == "typescriptreact"
          )

          if is_jsy and cur then
            local cur_type = cur:type()
            local interpolation_surround = { { "${" }, { "}" } }
            if cur and (cur_type == "string" or cur_type == "string_fragment") then
              vim.cmd.normal("csq`")
              return interpolation_surround
            elseif cur and cur_type == "template_string" then
              return interpolation_surround
            else
              return { { "`${" }, { "}`" } }
            end
          end
        end,
      },
      -- markdown code block
      ["~"] = {
        add = function()
          local ft = vim.bo.filetype
          if ft == "markdown" then
            local config = require("nvim-surround.config")
            local result = config.get_input("Enter the language: ")
            if result then
              return { { "```" .. result .. "\n" }, { "\n```" } }
            else
              return { { "```" }, { "\n```" } }
            end
          end
        end,
      },
      -- "generics"
      ["g"] = {
        add = function()
          local config = require("nvim-surround.config")
          local result = config.get_input("Enter the generic name: ")
          if result then
            return { { result .. "<" }, { ">" } }
          end
        end,
        find = function()
          local config = require("nvim-surround.config")
          return config.get_selection({ node = "generic_type" })
        end,
        delete = "^(.-<)().-(>)()$",
        change = {
          target = "^(.-<)().-(>)()$",
          replacement = function()
            local config = require("nvim-surround.config")
            local result = config.get_input("Enter the generic name: ")
            if result then
              return { { result .. "<" }, { ">" } }
            end
          end,
        },
      },
    },
  },
}
